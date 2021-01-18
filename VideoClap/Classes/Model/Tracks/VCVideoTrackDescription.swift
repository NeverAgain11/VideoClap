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
    
    public override func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCVideoTrackDescription()
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
        copyObj.sourceTimeRange  = sourceTimeRange
        copyObj.associationInfo  = associationInfo
        return copyObj
    }
    
    public override func originImage(time: CMTime, renderSize: CGSize = .zero, renderScale: CGFloat = 1.0, compensateTimeRange: CMTimeRange?) -> CIImage? {
        locker.object(forKey: #function).lock()
        defer {
            locker.object(forKey: #function).unlock()
        }
        let storeKey = id + "_\(time.value)_\(time.timescale)"
        if let cacheImage = VCImageCache.share.image(forKey: storeKey) {
            return cacheImage
        } else if let videoUrl = self.mediaURL {
            var frame: CIImage?
            let asset = AVAsset(url: videoUrl)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceAfter = .zero
            generator.requestedTimeToleranceBefore = .zero
            generator.maximumSize = renderSize.scaling(renderScale)
            
            do {
                let cgimage = try generator.copyCGImage(at: time, actualTime: nil)
                let ciimage = CIImage(cgImage: cgimage)
                VCImageCache.share.storeImage(toMemory: ciimage, forKey: storeKey)
                frame = ciimage
            } catch {
                frame = nil
            }
            return frame
        }
        return nil
    }
    
    public override func compositionImage(sourceFrame: CIImage, compositionTime: CMTime, renderSize: CGSize, renderScale: CGFloat, compensateTimeRange: CMTimeRange?) -> CIImage? {
        let actualRenderSize = renderSize.scaling(renderScale)
        var frame: CIImage = sourceFrame
        // 对视频帧降采样
        if max(actualRenderSize.width, actualRenderSize.height) > max(sourceFrame.extent.width, sourceFrame.extent.height) {
            
        } else {
            let widthRatio: CGFloat = actualRenderSize.width / frame.extent.width
            let heightRatio: CGFloat = actualRenderSize.height / frame.extent.height
            let scale = widthRatio < 1.0 ? widthRatio : heightRatio
            frame = frame.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            
            if let cgImage = CIContext.share.createCGImage(frame, from: CGRect(origin: .zero, size: frame.extent.size)) {
                frame = CIImage(cgImage: cgImage)
            }
        }
        return process(image: frame, compositionTime: compositionTime, renderSize: renderSize, renderScale: renderScale, compensateTimeRange: compensateTimeRange)
    }
    
}
