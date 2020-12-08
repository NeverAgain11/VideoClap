//
//  VCVideoCompositor.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/22.
//

import Foundation
import GLKit
import AVFoundation

internal enum VCVideoCompositorError: Error {
    case noVideoFile(String)
    case noAudioFile(String)
    case videoIsNotPlayable(String)
    case audioIsNotPlayable(String)
    case noVideoTrack(String)
    case noAudioTrack(String)
    case internalError
}

internal class VCVideoCompositor: NSObject {
    
    internal static let EmptyVideoTrackID = CMPersistentTrackID(3000 - 1)
    
    internal static let MediaTrackIDHeader = CMPersistentTrackID(3000)
    
    private var videoDescription: VCVideoDescription {
        return requestCallbackHandler.videoDescription
    }
    
    private lazy var blackVideoAsset: AVURLAsset = {
        let url = VCHelper.bundle().url(forResource: "black30s.mov", withExtension: nil) ?? URL(fileURLWithPath: "")
        return AVURLAsset(url: url)
    }()
    
    private var requestCallbackHandler: VCRequestCallbackHandlerProtocol
    
    init(requestCallbackHandler: VCRequestCallbackHandlerProtocol) {
        self.requestCallbackHandler = requestCallbackHandler
    }
    
    internal func playerItemForPlay() throws -> AVPlayerItem {
        let composition = AVMutableComposition(urlAssetInitializationOptions: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        
        let videoDuration = estimateVideoDuration()
        guard let compositionTrack = self.compositionTrack(at: composition, withMediaType: .video, trackID: VCVideoCompositor.EmptyVideoTrackID) else {
            throw VCVideoCompositorError.internalError
        }
        try addEmptyTrack(timeRange: CMTimeRange(start: .zero, duration: videoDuration), onCompositionTrack: compositionTrack)
        let trackBundle = videoDescription.trackBundle
        let existVideoTrackDic = addVideoTracks(persistentTrackHeaderID: VCVideoCompositor.MediaTrackIDHeader,
                                                videoTracks: trackBundle.videoTracks,
                                                compositionVideoDuration: videoDuration,
                                                composition: composition)
        
        var audioTrackHeaderID: CMPersistentTrackID = VCVideoCompositor.MediaTrackIDHeader
        if let videoTrackTailID = existVideoTrackDic.keys.max() {
            audioTrackHeaderID = videoTrackTailID + 1
        }
        let existAudioTrackDic = addAudioTracks(persistentTrackHeaderID: audioTrackHeaderID,
                                                audioTracks: trackBundle.audioTracks,
                                                compositionVideoDuration: videoDuration,
                                                composition: composition)
        
        var audioMixInputParametersGroup: [AVMutableAudioMixInputParameters] = []
        
        for (_, trackInfos) in existAudioTrackDic {
            for audioTrack in trackInfos {
                if let compositionTrack = audioTrack.compositionTrack,
                    let inputParameters = addAudioMix(audioTrack: compositionTrack,
                                                     audioTrackID: audioTrack.persistentTrackID,
                                                     track: audioTrack) {
                    audioMixInputParametersGroup.append(inputParameters)
                }
            }
        }
        
        var audioMix: AVMutableAudioMix?
        if audioMixInputParametersGroup.isEmpty == false {
            audioMix = AVMutableAudioMix()
            audioMix?.inputParameters = audioMixInputParametersGroup
        }
        
        var instructions = buildVideoInstruction(videoTracks: existVideoTrackDic.flatMap({ $0.value }),
                                                 audioTracks: existAudioTrackDic.flatMap({ $0.value }))
        
        if instructions.isEmpty {
            let emptyInstruction = VCVideoInstruction()
            emptyInstruction.timeRange = CMTimeRange(start: .zero, duration: videoDuration)
            emptyInstruction.requiredSourceTrackIDs = [VCVideoCompositor.EmptyVideoTrackID as NSValue]
            emptyInstruction.videoProcessProtocol = self.requestCallbackHandler
            instructions.append(emptyInstruction)
        }
        
        let videoComposition = buildVideoComposition(videoDescription: videoDescription, instructions: instructions)
        
        let newPlayerItem = AVPlayerItem(asset: composition)
        newPlayerItem.audioMix = audioMix
        newPlayerItem.videoComposition = videoComposition
        return newPlayerItem
    }
    
    internal func setRequestCallbackHandler(_ handler: VCRequestCallbackHandlerProtocol) {
        requestCallbackHandler = handler
    }
    
    internal func estimateVideoDuration() -> CMTime {
        let trackBundle = videoDescription.trackBundle
        let tracks = trackBundle.allTracks()
        let duration = tracks.max { (lhs, rhs) -> Bool in
            return lhs.timeRange.end < rhs.timeRange.end
        }?.timeRange.end ?? .zero
        return CMTime(seconds: duration.seconds)
    }
    
    private func canInsertTimeRange(_ timeRange: CMTimeRange, atExistingTimeRanges existingTimeRanges: [CMTimeRange]) -> Bool {
        if existingTimeRanges.isEmpty {
            return true
        }
        
        for existingTimeRange in existingTimeRanges {
            let intersection = existingTimeRange.intersection(timeRange)
            if intersection.isEmpty {
                continue
            } else {
                return false
            }
        }
        
        return true
    }
    
    private func addVideoTracks(persistentTrackHeaderID: CMPersistentTrackID,
                                videoTracks: [VCVideoTrackDescription],
                                compositionVideoDuration: CMTime,
                                composition: AVMutableComposition) -> [CMPersistentTrackID : [VCVideoTrackDescription]] {
        return addMediaTracks(persistentTrackHeaderID: persistentTrackHeaderID,
                              mediaTracks: videoTracks,
                              mediaType: .video,
                              compositionVideoDuration: compositionVideoDuration,
                              composition: composition) as! [CMPersistentTrackID : [VCVideoTrackDescription]] 
    }
    
    private func addAudioTracks(persistentTrackHeaderID: CMPersistentTrackID,
                                audioTracks: [VCAudioTrackDescription],
                                compositionVideoDuration: CMTime,
                                composition: AVMutableComposition) -> [CMPersistentTrackID : [VCAudioTrackDescription]] {
        return addMediaTracks(persistentTrackHeaderID: persistentTrackHeaderID,
                              mediaTracks: audioTracks,
                              mediaType: .audio,
                              compositionVideoDuration: compositionVideoDuration,
                              composition: composition) as! [CMPersistentTrackID : [VCAudioTrackDescription]]
    }
    
    private func addMediaTracks(persistentTrackHeaderID: CMPersistentTrackID,
                                mediaTracks: [VCMediaTrackDescriptionProtocol],
                                mediaType: AVMediaType,
                                compositionVideoDuration: CMTime,
                                composition: AVMutableComposition) -> [CMPersistentTrackID : [VCMediaTrackDescriptionProtocol]] {
        
        var persistentTrackID = persistentTrackHeaderID
        
        var existTrackInfoDic: [CMPersistentTrackID : [VCMediaTrackDescriptionProtocol]] = [:]
        
        for mediaTrack in mediaTracks {
            if let mediaURL = mediaTrack.mediaURL {
                let asset = AVAsset(url: mediaURL)
                
                if let bestVideoTrack = asset.tracks(withMediaType: mediaType).first, let assetDuration = bestVideoTrack.asset?.duration {
                    
                    if let trackInfos = existTrackInfoDic[persistentTrackID] {
                        let existTimeRanges = trackInfos.map({ $0.timeRange })
                        if canInsertTimeRange(mediaTrack.timeRange, atExistingTimeRanges: existTimeRanges) {
                             
                        } else {
                            persistentTrackID += 1
                        }
                    }
                    
                    if let compositionTrack = compositionTrack(at: composition, withMediaType: mediaType, trackID: persistentTrackID) {
                        do {
                            var fixStart: CMTime = .zero
                            var fixEnd: CMTime = .zero
                            fixStart = min(max(CMTime.zero, mediaTrack.mediaClipTimeRange.start), assetDuration)
                            fixEnd = min(max(fixStart, mediaTrack.mediaClipTimeRange.end), assetDuration)
                            var fixClipTimeRange: CMTimeRange = CMTimeRange(start: fixStart, end: fixEnd)
                            
                            let maxClipDuration = compositionVideoDuration - mediaTrack.timeRange.start
                            if fixClipTimeRange.duration > maxClipDuration {
                                fixClipTimeRange = CMTimeRange(start: fixClipTimeRange.start, duration: maxClipDuration)
                            }
                            
                            try compositionTrack.insertTimeRange(fixClipTimeRange, of: bestVideoTrack, at: mediaTrack.timeRange.start)
                            mediaTrack.fixClipTimeRange = fixClipTimeRange
                            mediaTrack.persistentTrackID = persistentTrackID
                            mediaTrack.compositionTrack = compositionTrack
                            if var trackInfos = existTrackInfoDic[persistentTrackID] {
                                trackInfos.append(mediaTrack)
                                existTrackInfoDic[persistentTrackID] = trackInfos
                            } else {
                                existTrackInfoDic[persistentTrackID] = [mediaTrack]
                            }
                        } catch let error {
                            log.error(error)
                        }
                    }
                    
                }
                
            }
        }
        
        return existTrackInfoDic
    }
    
    private func compositionTrack(at composition: AVMutableComposition, withMediaType mediaType: AVMediaType, trackID: CMPersistentTrackID) -> AVMutableCompositionTrack? {
        var optionalCompositionTrack = composition.track(withTrackID: trackID)
        if optionalCompositionTrack == nil {
            optionalCompositionTrack = composition.addMutableTrack(withMediaType: mediaType, preferredTrackID: trackID)
        }
        return optionalCompositionTrack
    }
    
    private func buildVideoInstruction(videoTracks: [VCVideoTrackDescription], audioTracks: [VCAudioTrackDescription]) -> [VCVideoInstruction] {
        let locker = VCLocker()
        let trackBundle = videoDescription.trackBundle
        let imageTracks = trackBundle.imageTracks
        let lottieTracks = trackBundle.lottieTracks
        let laminationTracks = trackBundle.laminationTracks
        let textTracks = trackBundle.textTracks
        
        let trackDescriptions: [VCImageTrackDescription] = imageTracks + videoTracks
        let enumor = trackDescriptions.reduce([:]) { (result, track) -> [String : VCImageTrackDescription] in
            var mutable = result
            mutable[track.id] = track
            return mutable
        }
        
        var transitions: [VCTransition] = []
        
        for track in trackDescriptions {
            if let trajectory = track.trajectory {
                let start =  track.timeRange.start.seconds + TimeInterval(trajectory.range.left) * track.timeRange.duration.seconds
                let end =  track.timeRange.start.seconds + TimeInterval(trajectory.range.right) * track.timeRange.duration.seconds
                trajectory.timeRange = CMTimeRange(start: start, end: end)
            }
        }
        
        (videoDescription.transitions as NSArray).enumerateObjects(options: .concurrent) { (obj, index, outStop) in
            guard let transition = obj as? VCTransitionProtocol else { return }
            guard enumor[transition.fromId] != nil || enumor[transition.toId] != nil else { return }
            guard let fromTrack = enumor[transition.fromId], let toTrack = enumor[transition.toId], fromTrack.timeRange.end >= toTrack.timeRange.start else { return }

            if fromTrack.timeRange.end == toTrack.timeRange.start {
                // 两个轨道没有重叠，但是需要过渡动画，根据 'range' 计算出过渡时间
                let start: CMTime = CMTime(seconds: fromTrack.timeRange.end.seconds - fromTrack.timeRange.duration.seconds * Double(transition.range.left))
                let end: CMTime = CMTime(seconds: toTrack.timeRange.start.seconds + toTrack.timeRange.duration.seconds * Double(transition.range.right))
                
                let t: VCTransition = VCTransition(timeRange: CMTimeRange(start: start, end: end), transition: transition)
                
                t.fromTrackClipTimeRange = (fromTrack as? VCVideoTrackDescription)?.fixClipTimeRange
                t.toTrackClipTimeRange = (toTrack as? VCVideoTrackDescription)?.fixClipTimeRange
                
                if let trajectory = fromTrack.trajectory {
                    let duration = (end - fromTrack.timeRange.start).seconds
                    let start =  fromTrack.timeRange.start.seconds + TimeInterval(trajectory.range.left) * duration
                    let end =  fromTrack.timeRange.start.seconds + TimeInterval(trajectory.range.right) * duration
                    trajectory.timeRange = CMTimeRange(start: start, end: end)
                }
                
                if let trajectory = toTrack.trajectory {
                    let duration = (toTrack.timeRange.end - start).seconds
                    let trajectoryStart = start.seconds + TimeInterval(trajectory.range.left) * duration
                    let trajectoryEnd = start.seconds + TimeInterval(trajectory.range.right) * duration
                    trajectory.timeRange = CMTimeRange(start: trajectoryStart,
                                                       end: trajectoryEnd)
                }
                
                locker.object(forKey: "transitions").lock()
                transitions.append(t)
                locker.object(forKey: "transitions").unlock()
            } else if fromTrack.timeRange.end > toTrack.timeRange.start {
                // 两个轨道有重叠
                let t: VCTransition = VCTransition(timeRange: CMTimeRange(start: toTrack.timeRange.start, end: fromTrack.timeRange.end), transition: transition)
                locker.object(forKey: "transitions").lock()
                transitions.append(t)
                locker.object(forKey: "transitions").unlock()
            }
            
        }
        
        var instructions: [VCVideoInstruction] = []
        var timeRanges: [CMTimeRange] = []
        var cursor: CMTime = .zero
        var keyTimes: [CMTime] = []
        
        keyTimes.append(contentsOf: imageTracks.flatMap({ [$0.timeRange.start, $0.timeRange.end] }))
        keyTimes.append(contentsOf: videoTracks.flatMap({ [$0.timeRange.start, $0.timeRange.end] }))
        keyTimes.append(contentsOf: lottieTracks.flatMap({ [$0.timeRange.start, $0.timeRange.end] }))
        keyTimes.append(contentsOf: laminationTracks.flatMap({ [$0.timeRange.start, $0.timeRange.end] }))
        keyTimes.append(contentsOf: audioTracks.flatMap({ [$0.timeRange.start, $0.timeRange.end] }))
        keyTimes.append(contentsOf: transitions.flatMap({ [$0.timeRange.start, $0.timeRange.end] }))
        keyTimes.append(contentsOf: textTracks.flatMap({ [$0.timeRange.start, $0.timeRange.end] }))
        
        func removeDuplicates(times: [CMTime]) -> [CMTime] {
            var fastEnum: [String:CMTime] = [:]
            for item in times {
                fastEnum["\(item.value) -- \(item.timescale)"] = item
            }
            return fastEnum.map({ $0.value })
        }
        keyTimes = removeDuplicates(times: keyTimes)
        
        while true {
            let greaterThanCursorTimes = keyTimes.filter({ $0 > cursor })
            if let minTime = greaterThanCursorTimes.min() {
                let range = CMTimeRange(start: cursor, end: minTime)
                timeRanges.append(range)
                cursor = minTime
            } else {
                break
            }
        }
        
        (timeRanges as NSArray).enumerateObjects(options: .concurrent) { (obj: Any, _, _) in
            guard let timeRange = obj as? CMTimeRange else { return }
            let trackBundle = VCTrackBundle()
            let instruction = VCVideoInstruction()
            instruction.trackBundle = trackBundle
            
            trackBundle.imageTracks = imageTracks.filter({ $0.timeRange.intersection(timeRange).isEmpty == false })
            trackBundle.videoTracks = videoTracks.filter({ $0.timeRange.intersection(timeRange).isEmpty == false })
            trackBundle.lottieTracks = lottieTracks.filter({ $0.timeRange.intersection(timeRange).isEmpty == false })
            trackBundle.laminationTracks = laminationTracks.filter({ $0.timeRange.intersection(timeRange).isEmpty == false })
            trackBundle.audioTracks = audioTracks.filter({ $0.timeRange.intersection(timeRange).isEmpty == false })
            trackBundle.textTracks = textTracks.filter({ $0.timeRange.intersection(timeRange).isEmpty == false })
            
            if trackBundle.videoTracks.isEmpty {
                instruction.requiredSourceTrackIDs = [VCVideoCompositor.EmptyVideoTrackID as NSValue]
            } else {
                instruction.requiredSourceTrackIDsDic = trackBundle.videoTracks.reduce([:]) { (result, trackInfo: VCVideoTrackDescription) -> [CMPersistentTrackID : VCVideoTrackDescription] in
                    var mutable = result
                    mutable[trackInfo.persistentTrackID] = trackInfo
                    return mutable
                }
                instruction.requiredSourceTrackIDs = instruction.requiredSourceTrackIDsDic.map({ $0.key as NSValue })
            }

            instruction.transitions = transitions.filter({ $0.timeRange.intersection(timeRange).isEmpty == false })
            
            for transition in instruction.transitions {
                
                let fromTrack = enumor[transition.transition.fromId]
                let toTrack = enumor[transition.transition.toId]
                
                switch fromTrack {
                case let track as VCVideoTrackDescription:
                    if trackBundle.videoTracks.contains(where: { track.id == $0.id }) == false {
                        trackBundle.videoTracks.append(track)
                    }
                    
                case let track as VCImageTrackDescription:
                    if trackBundle.imageTracks.contains(where: { track.id == $0.id }) == false {
                        trackBundle.imageTracks.append(track)
                    }
                    
                default:
                    break
                }
                
                switch toTrack {
                case let track as VCVideoTrackDescription:
                    if trackBundle.videoTracks.contains(where: { track.id == $0.id }) == false {
                        trackBundle.videoTracks.append(track)
                    }
                    
                case let track as VCImageTrackDescription:
                    if trackBundle.imageTracks.contains(where: { track.id == $0.id }) == false {
                        trackBundle.imageTracks.append(track)
                    }
                    
                default:
                    break
                }
            }
            
            instruction.timeRange = timeRange
            instruction.videoProcessProtocol = self.requestCallbackHandler
            
            locker.object(forKey: "instructions").lock()
            instructions.append(instruction)
            locker.object(forKey: "instructions").unlock()
        }
        
        instructions = instructions.sorted { (lhs, rhs) -> Bool in
            return lhs.timeRange.start < rhs.timeRange.start
        }
        
//        for instruction in instructions {
//            print("---------------- **** --------------------")
            
//            print(instruction.timeRange.debugDescription, "\n")
//
//            print("videoTracks info: ", instruction.videoTracks, instruction.videoTracks.map({ $0.id }), "\n")
//
//            print("videoTracks imageTracks: ", instruction.imageTracks, instruction.imageTracks.map({ $0.id }), "\n")
//
//            print(instruction.requiredSourceTrackIDs)
//
//            print(instruction.requiredSourceTrackIDsDic.map({ ($0.key, $0.value.id) }))
//
//            print("transitions info: ", instruction.transitions.map({ ($0.transition.fromId, $0.transition.toId) }))
            
//            print("trajectories info: ", instruction.trajectories, instruction.trajectories.map({ ($0.timeRange, $0.id) }))
            
//            print("---------------- **** --------------------\n")
//        }
        
        return instructions
    }
    
    private func buildVideoComposition(videoDescription: VCVideoDescription, instructions: [VCVideoInstruction]) -> AVMutableVideoComposition {
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTime(seconds: 1 / videoDescription.fps, preferredTimescale: 600)
        videoComposition.instructions = instructions
        videoComposition.customVideoCompositorClass = VCVideoCompositing.self
        videoComposition.renderSize = videoDescription.renderSize
        videoComposition.renderScale = videoDescription.renderScale
        return videoComposition
    }
    
    private func addAudioMix(audioTrack: AVMutableCompositionTrack, audioTrackID: CMPersistentTrackID, track: VCAudioTrackDescription) -> AVMutableAudioMixInputParameters? {
        if track.audioVolumeRampDescriptions.isEmpty {
            return nil
        }
        
        let inputParams = AVMutableAudioMixInputParameters(track: audioTrack)
        inputParams.trackID = audioTrackID
        var existTimeRanges: [CMTimeRange] = []
        for audioVolumeRampDescription in track.audioVolumeRampDescriptions {
            guard audioVolumeRampDescription.timeRange.isValid else {
                continue
            }
            
            for existTimeRange in existTimeRanges {
                if existTimeRange.intersection(audioVolumeRampDescription.timeRange).isEmpty == false {
                    continue
                }
            }
            
            inputParams.setVolumeRamp(fromStartVolume: audioVolumeRampDescription.startVolume,
                                      toEndVolume: audioVolumeRampDescription.endVolume,
                                      timeRange: audioVolumeRampDescription.timeRange)
            existTimeRanges.append(audioVolumeRampDescription.timeRange)
        }
        
        do {
            let cookie = VCTapToken(trackID: track.id, processCallback: requestCallbackHandler)
            try inputParams.setAudioProcessingTap(cookie: cookie)
        } catch let error {
            log.error(error)
        }
        
        return inputParams
    }
    
    private func addEmptyTrack(timeRange: CMTimeRange, onCompositionTrack compositionTrack: AVMutableCompositionTrack) throws {
        guard let blackVideoTrack = blackVideoAsset.tracks(withMediaType: .video).first else {
            throw VCVideoCompositorError.internalError
        }
        struct InsertDescription {
            let duraionValue: CMTimeValue
            let insertTimeValue: CMTimeValue
        }
        var insertDescriptions: [InsertDescription] = []
        
        var timeRangeDurationValue = CMTime(seconds: timeRange.duration.seconds).value
        let blackVideoDurationValue = CMTime(seconds: blackVideoAsset.duration.seconds).value
        
        var append: Bool = false
        while timeRangeDurationValue - blackVideoDurationValue > 0 {
            let duraionValue: CMTimeValue = blackVideoDurationValue
            var insertTimeValue: CMTimeValue = 0
            if let lastInsertTimeValue = insertDescriptions.last?.insertTimeValue {
                insertTimeValue = lastInsertTimeValue + blackVideoDurationValue
            } else {
                insertTimeValue = timeRange.start.value
            }
            
            let insertDescription = InsertDescription(duraionValue: duraionValue, insertTimeValue: insertTimeValue)
            insertDescriptions.append(insertDescription)
            timeRangeDurationValue -= blackVideoDurationValue
            append = true
        }
        
        if append {
            let insertDescription = InsertDescription(duraionValue: timeRangeDurationValue,
                                                      insertTimeValue: (insertDescriptions.last?.insertTimeValue ?? 0) + timeRangeDurationValue)
            insertDescriptions.append(insertDescription)
        } else {
            let insertDescription = InsertDescription(duraionValue: timeRangeDurationValue,
                                                      insertTimeValue: timeRange.start.value)
            insertDescriptions.append(insertDescription)
        }
        
        for insertDescription in insertDescriptions {
            let range = CMTimeRange(start: .zero, duration: CMTime(value: insertDescription.duraionValue, timescale: 600))
            let time = CMTime(value: insertDescription.insertTimeValue, timescale: 600)
            try compositionTrack.insertTimeRange(range, of: blackVideoTrack, at: time)
        }
    }
    
}
