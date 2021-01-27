//
//  VCGIFTrackDescription.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/26.
//

import AVFoundation

public class VCGIFTrackDescription: VCImageTrackDescription {
    
    public override var mediaURL: URL? {
        didSet {
            if let url = mediaURL {
                imageSource = VCGIFSource(url: url)
                imageSource?.loadProperties()
            }
        }
    }
    
    public private(set) var imageSource: VCGIFSource?
    
    public override func originImage(time: CMTime, compensateTimeRange: CMTimeRange?) -> CIImage? {
        return self.originImage(time: time, renderSize: .zero, renderScale: .zero, compensateTimeRange: compensateTimeRange)
    }
    
    public override func originImage(time: CMTime, renderSize: CGSize, renderScale: CGFloat, compensateTimeRange: CMTimeRange?) -> CIImage? {
        locker.object(forKey: #function).lock()
        defer {
            locker.object(forKey: #function).unlock()
        }
        guard let imageSource = self.imageSource else { return nil }
        let image = imageSource.loopImage(at: time)
        return image
    }
    
    public override func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCGIFTrackDescription()
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
        copyObj.imageSource      = imageSource?.mutableCopy() as? VCGIFSource
        return copyObj
    }
    
}
