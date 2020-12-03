//
//  VCVideoTrackDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/22.
//

import AVFoundation

public class VCVideoTrackDescription: VCImageTrackDescription, VCMediaTrackDescriptionProtocol {
    
    public var associationInfo: MediaTrackAssociationInfo = .init()
    
    public var mediaClipTimeRange: CMTimeRange = .zero
    
    public override init() {
        super.init()
    }
    
    public override func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCVideoTrackDescription()
        copyObj.mediaURL = mediaURL
        copyObj.id = id
        copyObj.timeRange = timeRange
        copyObj.isFit = isFit
        copyObj.isFlipHorizontal = isFlipHorizontal
        copyObj.filterIntensity = filterIntensity
        copyObj.lutImageURL = lutImageURL
        copyObj.rotateRadian = rotateRadian
        copyObj.cropedRect = cropedRect
        copyObj.prefferdTransform = prefferdTransform
        copyObj.mediaClipTimeRange = mediaClipTimeRange
        return copyObj
    }
    
}
