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

class TrackInfo: NSObject {
    var persistentTrackID: CMPersistentTrackID
    var compositionTrack: AVMutableCompositionTrack
    var mediaTrack: VCMediaTrackDescriptionProtocol
    
    init(persistentTrackID: CMPersistentTrackID, compositionTrack: AVMutableCompositionTrack, mediaTrack: VCMediaTrackDescriptionProtocol) {
        self.compositionTrack = compositionTrack
        self.persistentTrackID = persistentTrackID
        self.mediaTrack = mediaTrack
    }
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
        guard let compositionTrack = self.getCompositionTrack(at: composition, withMediaType: .video, trackID: VCVideoCompositor.EmptyVideoTrackID) else {
            throw VCVideoCompositorError.internalError
        }
        try addEmptyTrack(timeRange: CMTimeRange(start: .zero, duration: videoDuration), onCompositionTrack: compositionTrack)
        
        let existVideoTrackDic = addVideoTracks(persistentTrackHeaderID: VCVideoCompositor.MediaTrackIDHeader,
                                                videoTracks: videoDescription.videoTracks,
                                                compositionVideoDuration: videoDuration,
                                                composition: composition)
        
        var audioTrackHeaderID: CMPersistentTrackID = VCVideoCompositor.MediaTrackIDHeader
        if let videoTrackTailID = existVideoTrackDic.keys.max() {
            audioTrackHeaderID = videoTrackTailID + 1
        }
        let existAudioTrackDic = addAudioTracks(persistentTrackHeaderID: audioTrackHeaderID,
                                                audioTracks: videoDescription.audioTracks,
                                                compositionVideoDuration: videoDuration,
                                                composition: composition)
        
        var audioMixInputParametersGroup: [AVMutableAudioMixInputParameters] = []
        
        for (_, trackInfos) in existAudioTrackDic {
            for trackInfo in trackInfos {
                if let audioTrack = trackInfo.mediaTrack as? VCAudioTrackDescription,
                   let inputParameters = addAudioMix(audioTrack: trackInfo.compositionTrack,
                                                     audioTrackID: trackInfo.persistentTrackID,
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
        
        let instructions = buildVideoInstruction(videoTrackInfos: existVideoTrackDic.flatMap({ $0.value }),
                                                 audioTrackInfos: existAudioTrackDic.flatMap({ $0.value }))
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
        let tracks = allTracks()
        let duration = tracks.max { (lhs, rhs) -> Bool in
            return lhs.timeRange.end < rhs.timeRange.end
        }?.timeRange.end ?? .zero
        return duration
    }
    
    private func allTracks() -> [VCTrackDescriptionProtocol] {
        var tracks: [VCTrackDescriptionProtocol] = []
        tracks.append(contentsOf: videoDescription.imageTracks)
        tracks.append(contentsOf: videoDescription.videoTracks)
        tracks.append(contentsOf: videoDescription.lottieTracks)
        tracks.append(contentsOf: videoDescription.laminationTracks)
        tracks.append(contentsOf: videoDescription.audioTracks)
        return tracks
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
                                composition: AVMutableComposition) -> [CMPersistentTrackID : [TrackInfo]] {
        return addMediaTracks(persistentTrackHeaderID: persistentTrackHeaderID,
                              mediaTracks: videoTracks,
                              mediaType: .video,
                              compositionVideoDuration: compositionVideoDuration,
                              composition: composition)
    }
    
    private func addAudioTracks(persistentTrackHeaderID: CMPersistentTrackID,
                                audioTracks: [VCAudioTrackDescription],
                                compositionVideoDuration: CMTime,
                                composition: AVMutableComposition) -> [CMPersistentTrackID : [TrackInfo]] {
        return addMediaTracks(persistentTrackHeaderID: persistentTrackHeaderID,
                              mediaTracks: audioTracks,
                              mediaType: .audio,
                              compositionVideoDuration: compositionVideoDuration,
                              composition: composition)
    }
    
    private func addMediaTracks(persistentTrackHeaderID: CMPersistentTrackID,
                                mediaTracks: [VCMediaTrackDescriptionProtocol],
                                mediaType: AVMediaType,
                                compositionVideoDuration: CMTime,
                                composition: AVMutableComposition) -> [CMPersistentTrackID : [TrackInfo]] {
        
        var persistentTrackID = persistentTrackHeaderID
        
        var existTrackInfoDic: [CMPersistentTrackID : [TrackInfo]] = [:]
        
        for mediaTrack in mediaTracks {
            if let mediaURL = mediaTrack.mediaURL {
                let asset = AVAsset(url: mediaURL)
                
                if let bestVideoTrack = asset.tracks(withMediaType: mediaType).first, let assetDuration = bestVideoTrack.asset?.duration {
                    
                    if let trackInfos = existTrackInfoDic[persistentTrackID] {
                        let existTimeRanges = trackInfos.map({ $0.mediaTrack.timeRange })
                        if canInsertTimeRange(mediaTrack.timeRange, atExistingTimeRanges: existTimeRanges) {
                             
                        } else {
                            persistentTrackID += 1
                        }
                    }
                    
                    if let compositionTrack = getCompositionTrack(at: composition, withMediaType: mediaType, trackID: persistentTrackID) {
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
                            if var trackInfos = existTrackInfoDic[persistentTrackID] {
                                trackInfos.append(TrackInfo(persistentTrackID: persistentTrackID,
                                                           compositionTrack: compositionTrack,
                                                           mediaTrack: mediaTrack))
                                existTrackInfoDic[persistentTrackID] = trackInfos
                            } else {
                                let trackInfo = TrackInfo(persistentTrackID: persistentTrackID,
                                                          compositionTrack: compositionTrack,
                                                          mediaTrack: mediaTrack)
                                existTrackInfoDic[persistentTrackID] = [trackInfo]
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
    
    private func getCompositionTrack(at composition: AVMutableComposition, withMediaType mediaType: AVMediaType, trackID: CMPersistentTrackID) -> AVMutableCompositionTrack? {
        var optionalCompositionTrack = composition.track(withTrackID: trackID)
        if optionalCompositionTrack == nil {
            optionalCompositionTrack = composition.addMutableTrack(withMediaType: mediaType, preferredTrackID: trackID)
        }
        return optionalCompositionTrack
    }
    
    private func buildVideoInstruction(videoTrackInfos: [TrackInfo], audioTrackInfos: [TrackInfo]) -> [VCVideoInstruction] {
        let locker = VCLocker()
        
        let imageTracks = videoDescription.imageTracks
        let videoTracks = videoTrackInfos.map({ $0.mediaTrack }) as? [VCVideoTrackDescription] ?? []
        let audioTracks = audioTrackInfos.map({ $0.mediaTrack }) as? [VCAudioTrackDescription] ?? []
        let lottieTracks = videoDescription.lottieTracks
        let laminationTracks = videoDescription.laminationTracks
        
        let trackDescriptions: [VCTrackDescriptionProtocol] = imageTracks + videoTracks
        let enumor = trackDescriptions.reduce([:]) { (result, track) -> [String : VCTrackDescriptionProtocol] in
            var mutable = result
            mutable[track.id] = track
            return mutable
        }
        
        var transitions: [VCTransition] = []
        
        (videoDescription.transitions as NSArray).enumerateObjects(options: .concurrent) { (obj, index, outStop) in
            guard let transition = obj as? VCTransitionProtocol else { return }
            
            if enumor[transition.fromId] != nil || enumor[transition.toId] != nil {
                if let fromTrack = enumor[transition.fromId], let toTrack = enumor[transition.toId], fromTrack.timeRange.end >= toTrack.timeRange.start {
                    
                    if fromTrack.timeRange.end == toTrack.timeRange.start {
                        // 两个轨道没有重叠，但是需要过渡动画，根据 'range' 计算出过渡时间
                        let start: CMTime = CMTime(seconds: fromTrack.timeRange.end.seconds - fromTrack.timeRange.duration.seconds * Double(transition.range.left))
                        let end: CMTime = CMTime(seconds: toTrack.timeRange.start.seconds + toTrack.timeRange.duration.seconds * Double(transition.range.right))
                        locker.object(forKey: "transitions").lock()
                        transitions.append(VCTransition(timeRange: CMTimeRange(start: start, end: end),
                                                       transition: transition))
                        locker.object(forKey: "transitions").unlock()
                    } else if fromTrack.timeRange.end > toTrack.timeRange.start {
                        // 两个轨道有重叠
                        locker.object(forKey: "transitions").lock()
                        transitions.append(VCTransition(timeRange: CMTimeRange(start: toTrack.timeRange.start, end: fromTrack.timeRange.end),
                                                       transition: transition))
                        locker.object(forKey: "transitions").unlock()
                    }
                }
            }
            
        }
        
        var instructions: [VCVideoInstruction] = []
        var timeRanges: [CMTimeRange] = []
        var cursor: CMTime = .zero
        var allKeyTime: [CMTime] = []
        
        allKeyTime.append(contentsOf: imageTracks.flatMap({ [$0.timeRange.start, $0.timeRange.end] }))
        allKeyTime.append(contentsOf: videoTracks.flatMap({ [$0.timeRange.start, $0.timeRange.end] }))
        allKeyTime.append(contentsOf: lottieTracks.flatMap({ [$0.timeRange.start, $0.timeRange.end] }))
        allKeyTime.append(contentsOf: laminationTracks.flatMap({ [$0.timeRange.start, $0.timeRange.end] }))
        allKeyTime.append(contentsOf: audioTracks.flatMap({ [$0.timeRange.start, $0.timeRange.end] }))
        allKeyTime.append(contentsOf: transitions.flatMap({ [$0.timeRange.start, $0.timeRange.end] }))
        
        func removeDuplicates(times: [CMTime]) -> [CMTime] {
            var fastEnum: [String:CMTime] = [:]
            for item in times {
                fastEnum["\(item.value) -- \(item.timescale)"] = item
            }
            return fastEnum.map({ $0.value })
        }
        allKeyTime = removeDuplicates(times: allKeyTime)
        
        while true {
            let ts = allKeyTime.filter({ $0 > cursor })
            if let minTime = ts.min() {
                let range = CMTimeRange(start: cursor, end: minTime)
                timeRanges.append(range)
                cursor = minTime
            } else {
                break
            }
        }
        
        (timeRanges as NSArray).enumerateObjects(options: .concurrent) { (obj: Any, _, _) in
            guard let timeRange = obj as? CMTimeRange else { return }

            let instruction = VCVideoInstruction()
            instruction.imageTracks = imageTracks.filter({ $0.timeRange.intersection(timeRange).isEmpty == false })
            instruction.videoTracks = videoTracks.filter({ $0.timeRange.intersection(timeRange).isEmpty == false })
            instruction.lottieTracks = lottieTracks.filter({ $0.timeRange.intersection(timeRange).isEmpty == false })
            instruction.laminationTracks = laminationTracks.filter({ $0.timeRange.intersection(timeRange).isEmpty == false })
            instruction.audioTracks = audioTracks.filter({ $0.timeRange.intersection(timeRange).isEmpty == false })
            
            if instruction.videoTracks.isEmpty {
                instruction.requiredSourceTrackIDs = [VCVideoCompositor.EmptyVideoTrackID as NSValue]
            } else {
                instruction.requiredSourceTrackIDsDic = videoTrackInfos.reduce([:]) { (result, trackInfo) -> [CMPersistentTrackID : VCVideoTrackDescription] in
                    var mutable = result
                    mutable[trackInfo.persistentTrackID] = trackInfo.mediaTrack as? VCVideoTrackDescription
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
                    if instruction.videoTracks.contains(where: { track.id == $0.id }) == false {
                        instruction.videoTracks.append(track)
                    }
                    
                case let track as VCImageTrackDescription:
                    if instruction.imageTracks.contains(where: { track.id == $0.id }) == false {
                        instruction.imageTracks.append(track)
                    }
                    
                default:
                    break
                }
                
                switch toTrack {
                case let track as VCVideoTrackDescription:
                    if instruction.videoTracks.contains(where: { track.id == $0.id }) == false {
                        instruction.videoTracks.append(track)
                    }
                    
                case let track as VCImageTrackDescription:
                    if instruction.imageTracks.contains(where: { track.id == $0.id }) == false {
                        instruction.imageTracks.append(track)
                    }
                    
                default:
                    break
                }
            }
            
            for trajectory in videoDescription.trajectories {
                if enumor[trajectory.id] != nil {
                    instruction.trajectories.append(trajectory)
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
        for audioVolumeRampDescription in track.audioVolumeRampDescriptions {
            inputParams.setVolumeRamp(fromStartVolume: audioVolumeRampDescription.startVolume,
                                      toEndVolume: audioVolumeRampDescription.endVolume,
                                      timeRange: audioVolumeRampDescription.timeRange)
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
        
        var timeRangeDurationValue = timeRange.duration.value
        let blackVideoDurationValue = blackVideoAsset.duration.value
        
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
