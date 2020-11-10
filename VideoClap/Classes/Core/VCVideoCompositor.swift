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
    
    internal static let VideoTrackIDHeader = CMPersistentTrackID(3000)
    
    private var videoDescription: VCVideoDescriptionProtocol? {
        return requestCallbackHandler?.videoDescription
    }
    
    private lazy var blackVideoAsset: AVURLAsset = {
        let url = VCHelper.getBundle().url(forResource: "black30s.mov", withExtension: nil) ?? URL(fileURLWithPath: "")
        return AVURLAsset(url: url)
    }()
    
    private var requestCallbackHandler: VCRequestCallbackHandlerProtocol?
    
    internal func playerItemForPlay() -> AVPlayerItem {
        guard let videoDescription = self.videoDescription else {
            return AVPlayerItem(asset: AVAsset())  // FIXME: 暂时这样做
        }
        let composition = AVMutableComposition(urlAssetInitializationOptions: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let audioMix = addTracks(for: composition)
        let instructions = buildVideoInstruction()
        let videoComposition = buildVideoComposition(videoDescription: videoDescription, instructions: instructions)
        
        let newPlayerItem = AVPlayerItem(asset: composition)
        newPlayerItem.audioMix = audioMix
        newPlayerItem.videoComposition = videoComposition
        newPlayerItem.seekingWaitsForVideoCompositionRendering = true
        return newPlayerItem
    }
    
    internal func setRequestCallbackHandler(_ handler: VCRequestCallbackHandlerProtocol) {
        requestCallbackHandler = handler
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
    
    private func trackDescriptions() -> [VCTrack] {
        guard let videoDescription = self.videoDescription else { return [] }
        var videoTracks: [VCTrack] = []
        var audioTracks: [VCTrack] = []
        let videoTrackIDHeader = VCVideoCompositor.VideoTrackIDHeader
        var videoResourceEnd: CMTime = .zero // 所有视频轨道最大结束时间
        var audioResourceEnd: CMTime = .zero // 所有音频轨道最大结束时间
        
        for mediaTrack in videoDescription.mediaTracks.filter({ $0.trackType != .audio }) {
            var expectTrackID = videoTrackIDHeader
            while true {
                let existingTimeRangesAtExpectTrack = videoTracks.filter({ $0.persistentTrackID == expectTrackID }).map({ $0.timeRange })
                if canInsertTimeRange(mediaTrack.timeRange, atExistingTimeRanges: existingTimeRangesAtExpectTrack) {
                    let track = VCTrack(description: mediaTrack, persistentTrackID: expectTrackID)
                    videoTracks.append(track)
                    break
                }
                expectTrackID += 1
            }
        }
        
        videoResourceEnd = videoTracks.map({ $0.timeRange.end }).max() ?? .zero
        
        var audioTrackIDHeader = videoTrackIDHeader
        if let maxVideoTrackID = videoTracks.max(by: { (lhs, rhs) -> Bool in
            return lhs.persistentTrackID < rhs.persistentTrackID
        })?.persistentTrackID {
            audioTrackIDHeader = maxVideoTrackID + 1
        }
        
        for mediaTrack in videoDescription.mediaTracks.filter({ $0.trackType == .audio }) {
            var expectTrackID = audioTrackIDHeader
            while true {
                let existingTimeRangesAtExpectTrack = audioTracks.filter({ $0.persistentTrackID == expectTrackID }).map({ $0.timeRange })
                if canInsertTimeRange(mediaTrack.timeRange, atExistingTimeRanges: existingTimeRangesAtExpectTrack) {
                    let track = VCTrack(description: mediaTrack, persistentTrackID: expectTrackID)
                    audioTracks.append(track)
                    break
                }
                expectTrackID += 1
            }
        }
        
        audioResourceEnd = audioTracks.map({ $0.timeRange.end }).max() ?? .zero
        
        if audioResourceEnd > videoResourceEnd { // 如果音频的时间比视频的时间要长，需要在视频轨道中补充一个空的视频轨道，使得在补充了一个空的视频轨道后，视频轨道的时长要等于音频轨道时长
            let duration = audioResourceEnd - videoResourceEnd
            let start = videoResourceEnd
            let emptyTrack = VCTrack(description: VCTrackDescription(id: "", trackType: .stillImage, timeRange: CMTimeRange(start: start, duration: duration)),
                                     persistentTrackID: VCVideoCompositor.EmptyVideoTrackID)
            videoTracks.append(emptyTrack)
        }
        
        videoTracks.sort { (lhs, rhs) -> Bool in // 排序，需要保证在后续构建 VCVideoInstruction 集合时， videoTracks 是按顺序的
            return lhs.timeRange.start < rhs.timeRange.start
        }
        
        return videoTracks + audioTracks
    }
    
    private func getCompositionTrack(at composition: AVMutableComposition, withMediaType mediaType: AVMediaType, trackID: CMPersistentTrackID) -> AVMutableCompositionTrack? {
        var optionalCompositionTrack = composition.track(withTrackID: trackID)
        if optionalCompositionTrack == nil {
            optionalCompositionTrack = composition.addMutableTrack(withMediaType: mediaType, preferredTrackID: trackID)
        }
        return optionalCompositionTrack
    }
    
    private func addTracks(for composition: AVMutableComposition) -> AVMutableAudioMix? {
        let tracks: [VCTrack] = trackDescriptions()
        
        var audioMixInputParametersGroup: [AVMutableAudioMixInputParameters] = []
        for track in tracks {
            switch track.trackType {
            case .stillImage:
                guard let videoTrack = getCompositionTrack(at: composition, withMediaType: .video, trackID: track.persistentTrackID) else { continue }
                do {
                    try addStilImage(track: track, onCompositionTrack: videoTrack)
                } catch let error {
                    log.error(error)
                }
                
            case .video:
                guard let videoTrack = getCompositionTrack(at: composition, withMediaType: .video, trackID: track.persistentTrackID) else { continue }
                do {
                    try addVideo(track: track, onCompositionTrack: videoTrack)
                } catch let error {
                    log.error(error)
                }
                
            case .audio:
                guard let audioTrack = getCompositionTrack(at: composition, withMediaType: .audio, trackID: track.persistentTrackID) else { continue }
                
                do {
                    try addAudio(track: track, onCompositionTrack: audioTrack)
                    if let audioMixInputParameters = addAudioMix(audioTrack: audioTrack, audioTrackID: track.persistentTrackID, track: track) {
                        audioMixInputParametersGroup.append(audioMixInputParameters)
                    }
                } catch let error {
                    log.error(error)
                }
            }
        }
        
        var audioMix: AVMutableAudioMix?
        if audioMixInputParametersGroup.isEmpty == false {
            audioMix = AVMutableAudioMix()
            audioMix?.inputParameters = audioMixInputParametersGroup
        }
        return audioMix
    }
    
    private func buildVideoInstruction() -> [VCVideoInstruction] {
        let tracks: [VCTrack] = trackDescriptions().filter({ $0.trackType != .audio })
        var instructions: [VCVideoInstruction] = []
        var timeRanges: [CMTimeRange] = []
        var cursor: CMTime = .zero
        
        let allKeyTime: [CMTime] = tracks.map({ $0.timeRange.start }) + tracks.map({ $0.timeRange.end })
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
        for timeRange in timeRanges {
            let tracks = tracks.filter({ $0.timeRange.intersection(timeRange).isEmpty == false })
            let instruction = VCVideoInstruction(timeRange: timeRange, tracks: tracks)
            instruction.videoProcessProtocol = self.requestCallbackHandler
            instructions.append(instruction)
        }
        
        return instructions
    }
    
    private func buildVideoComposition(videoDescription: VCVideoDescriptionProtocol, instructions: [VCVideoInstruction]) -> AVMutableVideoComposition {
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTime(seconds: 1 / videoDescription.fps, preferredTimescale: 600)
        videoComposition.instructions = instructions
        videoComposition.customVideoCompositorClass = VCVideoCompositing.self
        videoComposition.renderSize = videoDescription.renderSize
        videoComposition.renderScale = videoDescription.renderScale
        return videoComposition
    }
    
    private func addVideo(track: VCTrack, onCompositionTrack compositionTrack: AVMutableCompositionTrack) throws {
        guard let mediaURL = track.mediaURL else {
            throw VCVideoCompositorError.noVideoFile(track.id)
        }
        let videoAsset = AVAsset(url: mediaURL)
        if videoAsset.isPlayable == false {
            throw VCVideoCompositorError.videoIsNotPlayable("\(mediaURL.path)不可播放")
        }
        guard let userTrack = videoAsset.tracks(withMediaType: .video).first else {
            throw VCVideoCompositorError.noVideoTrack("\(mediaURL.path)没有视频轨道")
        }
        let timeRange = CMTimeRange(start: track.mediaClipTimeRange.start, end: min(videoAsset.duration, track.mediaClipTimeRange.end))
        try compositionTrack.insertTimeRange(timeRange, of: userTrack, at: track.timeRange.start)
    }
    
    private func addAudio(track: VCTrack, onCompositionTrack compositionTrack: AVMutableCompositionTrack) throws {
        guard let mediaURL = track.mediaURL else {
            throw VCVideoCompositorError.noAudioFile(track.id)
        }
        let videoAsset = AVAsset(url: mediaURL)
        if videoAsset.isPlayable == false {
            throw VCVideoCompositorError.audioIsNotPlayable("\(mediaURL.path)不可播放")
        }
        guard let userTrack = videoAsset.tracks(withMediaType: .audio).first else {
            throw VCVideoCompositorError.noAudioTrack("\(mediaURL.path)没有音频轨道")
        }
        let timeRange = CMTimeRange(start: track.mediaClipTimeRange.start, end: min(videoAsset.duration, track.mediaClipTimeRange.end))
        try compositionTrack.insertTimeRange(timeRange, of: userTrack, at: track.timeRange.start)
    }
    
    private func addAudioMix(audioTrack: AVMutableCompositionTrack, audioTrackID: CMPersistentTrackID, track: VCTrack) -> AVMutableAudioMixInputParameters? {
        if track.audioVolumeRampDescriptions.isEmpty && requestCallbackHandler == nil {
            return nil
        }
        
        let inputParams = AVMutableAudioMixInputParameters(track: audioTrack)
        inputParams.trackID = audioTrackID
        for audioVolumeRampDescription in track.audioVolumeRampDescriptions {
            inputParams.setVolumeRamp(fromStartVolume: audioVolumeRampDescription.startVolume,
                                      toEndVolume: audioVolumeRampDescription.endVolume,
                                      timeRange: audioVolumeRampDescription.timeRange)
        }
        
        if let handler = requestCallbackHandler {
            do {
                let cookie = VCTapToken(trackID: track.id, processCallback: handler)
                handler.tapTokens.append(cookie)
                try inputParams.setAudioProcessingTap(cookie: cookie)
            } catch let error {
                log.error(error)
            }
        }
        
        return inputParams
    }
    
    private func addStilImage(track: VCTrack, onCompositionTrack compositionTrack: AVMutableCompositionTrack) throws {
        guard let blackVideoTrack = blackVideoAsset.tracks(withMediaType: .video).first else {
            throw VCVideoCompositorError.internalError
        }
        struct InsertDescription {
            let duraionValue: CMTimeValue
            let insertTimeValue: CMTimeValue
        }
        var insertDescriptions: [InsertDescription] = []
        
        var timeRangeDurationValue = track.timeRange.duration.value
        let blackVideoDurationValue = blackVideoAsset.duration.value
        
        var append: Bool = false
        while timeRangeDurationValue - blackVideoDurationValue > 0 {
            let duraionValue: CMTimeValue = blackVideoDurationValue
            var insertTimeValue: CMTimeValue = 0
            if let lastInsertTimeValue = insertDescriptions.last?.insertTimeValue {
                insertTimeValue = lastInsertTimeValue + blackVideoDurationValue
            } else {
                insertTimeValue = track.timeRange.start.value
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
                                                      insertTimeValue: track.timeRange.start.value)
            insertDescriptions.append(insertDescription)
        }
        
        for insertDescription in insertDescriptions {
            let range = CMTimeRange(start: .zero, duration: CMTime(value: insertDescription.duraionValue, timescale: 600))
            let time = CMTime(value: insertDescription.insertTimeValue, timescale: 600)
            try compositionTrack.insertTimeRange(range, of: blackVideoTrack, at: time)
        }
    }
    
}
