//
//  VCTrackDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

open class VCTrackDescription: NSObject, VCTrackDescriptionProtocol {
    
    public var id: String
    
    public var trackType: VCTrackType
    
    public var timeRange: CMTimeRange
    
    public var prefferdTransform: CGAffineTransform?
    
    public var mediaURL: URL?
    
    public var mediaClipTimeRange: CMTimeRange = .zero
    
    public var audioVolumeRampDescriptions: [VCAudioVolumeRampDescription] = []
    
    public var asyncImageClosure: (((CIImage?) -> Void) -> Void)?
    
    public init(id: String,
         trackType: VCTrackType,
         timeRange: CMTimeRange)
    {
        self.id = id
        self.trackType = trackType
        self.timeRange = timeRange
    }
    
    public func asyncImage(closure: (CIImage?) -> Void) {
        asyncImageClosure?(closure)
    }
    
    public func setAsyncImageClosure(closure: (((CIImage?) -> Void) -> Void)?) {
        asyncImageClosure = closure
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCTrackDescription(id: self.id, trackType: self.trackType, timeRange: self.timeRange)
        copyObj.prefferdTransform = self.prefferdTransform
        copyObj.mediaURL = self.mediaURL
        copyObj.mediaClipTimeRange = self.mediaClipTimeRange
        copyObj.asyncImageClosure = self.asyncImageClosure
        copyObj.audioVolumeRampDescriptions = self.audioVolumeRampDescriptions
        return copyObj
    }
    
}
