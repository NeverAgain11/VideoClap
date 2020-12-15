//
//  VCVideoTrackDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/22.
//

import AVFoundation

public class VCVideoTrackDescription: VCImageTrackDescription, VCMediaTrackDescriptionProtocol {
    
    public var sourceTimeRange: CMTimeRange = .zero
    
    public var associationInfo: MediaTrackAssociationInfo = .init()
    
    public var mediaClipTimeRange: CMTimeRange = .zero
    
    public var speed: Float {
        return Float(sourceTimeRange.duration.seconds / timeRange.duration.seconds)
    }
    
    internal var naturalSize: CGSize? {
        if let mediaURL = mediaURL {
            let asset = AVAsset(url: mediaURL)
            if asset.isPlayable && asset.tracks(withMediaType: .video).isEmpty == false {
                return asset.tracks.first?.naturalSize
            }
        }
        return nil
    }
    
    public override init() {
        super.init()
    }
    
    public override func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCVideoTrackDescription()
        copyObj.mediaURL           = mediaURL
        copyObj.id                 = id
        copyObj.sourceTimeRange    = sourceTimeRange
        copyObj.timeRange          = timeRange
        copyObj.isFit              = isFit
        copyObj.isFlipHorizontal   = isFlipHorizontal
        copyObj.filterIntensity    = filterIntensity
        copyObj.lutImageURL        = lutImageURL
        copyObj.rotateRadian       = rotateRadian
        copyObj.cropedRect         = cropedRect
        copyObj.trajectory         = trajectory
        copyObj.canvasStyle        = canvasStyle
        copyObj.associationInfo    = associationInfo
        return copyObj
    }
    
}
