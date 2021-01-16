//
//  VCLaminationTrackDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/6.
//

import AVFoundation

public class VCLaminationTrackDescription: VCImageTrackDescription {
    
    public override func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCLaminationTrackDescription()
        copyObj.mediaURL         = mediaURL
        copyObj.id               = id
        copyObj.timeRange        = timeRange
        copyObj.isFlipHorizontal = isFlipHorizontal
        copyObj.filterIntensity  = filterIntensity
        copyObj.lutImageURL      = lutImageURL
        copyObj.rotateRadian     = rotateRadian
        copyObj.cropedRect       = cropedRect
        copyObj.trajectory       = trajectory
        copyObj.canvasStyle      = canvasStyle
        copyObj.imageLayout      = imageLayout
        copyObj.indexPath        = indexPath
        return copyObj
    }
    
    public override func compositionImage(sourceFrame: CIImage, compositionTime: CMTime, renderSize: CGSize, renderScale: CGFloat, compensateTimeRange: CMTimeRange?) -> CIImage? {
        var laminationImage: CIImage = sourceFrame
        let scaleX = renderSize.width / laminationImage.extent.width
        let scaleY = renderSize.height / laminationImage.extent.height
        laminationImage = laminationImage.transformed(by: .init(scaleX: scaleX, y: scaleY))
        return laminationImage
    }
    
}
