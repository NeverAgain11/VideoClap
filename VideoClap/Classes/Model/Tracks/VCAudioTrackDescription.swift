//
//  VCAudioTrackDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/22.
//

import AVFoundation

public class VCAudioTrackDescription: NSObject, VCMediaTrackDescriptionProtocol {
    
    public var sourceTimeRange: CMTimeRange = .zero
    
    public var timeRange: CMTimeRange = .zero
    
    public var speed: Float {
        return Float(sourceTimeRange.duration.seconds / timeRange.duration.seconds)
    }
    
    public var associationInfo: MediaTrackAssociationInfo = .init()
    
    public var audioVolumeRampDescriptions: [VCAudioVolumeRampDescription] = []
    
    public var mediaURL: URL? = nil
    
    public var id: String = ""
    
    public var audioEffectProvider: VCAudioEffectProviderProtocol?
    
    public internal(set) var processingFormat: AVAudioFormat?
    
    public internal(set) var maxFrames: CMItemCount?
    
    public override init() {
        super.init()
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCAudioTrackDescription()
        copyObj.mediaURL                    = mediaURL
        copyObj.id                          = id
        copyObj.timeRange                   = timeRange
        copyObj.audioVolumeRampDescriptions = audioVolumeRampDescriptions
        copyObj.audioEffectProvider         = audioEffectProvider
        copyObj.sourceTimeRange             = sourceTimeRange
        copyObj.processingFormat            = processingFormat
        copyObj.maxFrames                   = maxFrames
        return copyObj
    }
    
    public func prepare(description: VCVideoDescription) {

    }
    
}

