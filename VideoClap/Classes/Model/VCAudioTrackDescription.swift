//
//  VCAudioTrackDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/22.
//

import AVFoundation

public class VCAudioTrackDescription: NSObject, VCTrackDescriptionProtocol, VCMediaTrackDescriptionProtocol {
    
    public var audioVolumeRampDescriptions: [VCAudioVolumeRampDescription] = []
    
    public var prefferdTransform: CGAffineTransform? = nil
    
    public var mediaClipTimeRange: CMTimeRange = .zero
    
    public var mediaURL: URL? = nil
    
    public var id: String = ""
    
    public var timeRange: CMTimeRange = .zero
    
    public var audioEffectProvider: VCAudioEffectProviderProtocol?
    
    public override init() {
        super.init()
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCAudioTrackDescription()
        copyObj.mediaURL = mediaURL
        copyObj.id = id
        copyObj.timeRange = timeRange
        copyObj.prefferdTransform = prefferdTransform
        copyObj.mediaClipTimeRange = mediaClipTimeRange
        copyObj.audioVolumeRampDescriptions = audioVolumeRampDescriptions
        copyObj.audioEffectProvider = audioEffectProvider
        return copyObj
    }
    
}

