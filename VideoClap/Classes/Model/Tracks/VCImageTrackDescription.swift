//
//  VCImageTrackDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/22.
//

import AVFoundation

public enum VCImageLayout: Equatable {
    case fit
    case fill
    case center(CGPoint)
    case rect(VCRect)
}

public class VCImageTrackDescription: NSObject, VCTrackDescriptionProtocol {
    
    public var mediaURL: URL? = nil
    
    public var id: String = ""
    
    public var prefferdTransform: CGAffineTransform? = nil
    
    public var timeRange: CMTimeRange = .zero
    
    public var isFlipHorizontal: Bool = false
    
    public var filterIntensity: NSNumber = 1.0
    
    public var lutImageURL: URL?
    
    /// 顺时针，弧度制，1.57顺时针旋转90度，3.14顺时针旋转180度
    public var rotateRadian: CGFloat = 0.0
    
    /// 归一化下裁剪区域，范围（0~1）
    public var cropedRect: CGRect?
    
    public var trajectory: VCTrajectoryProtocol?
    
    public var canvasStyle: VCCanvasStyle?
    
    public var imageLayout: VCImageLayout = .fit
    
    public var indexPath: IndexPath = IndexPath(item: 0, section: 0)
    
    public let locker = VCLocker()
    
    public internal(set) var trackCompensateTimeRange: CMTimeRange?
    
    public override init() {
        super.init()
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCImageTrackDescription()
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
    
    public func prepare(description: VCVideoDescription) {
        
    }
    
    public func originImage(time: CMTime, compensateTimeRange: CMTimeRange?) -> CIImage? {
        locker.object(forKey: #function).lock()
        defer {
            locker.object(forKey: #function).unlock()
        }
        guard let url = self.mediaURL else { return nil }
        return image(url: url, size: nil)
    }
    
    public func originImage(time: CMTime, renderSize: CGSize, renderScale: CGFloat, compensateTimeRange: CMTimeRange?) -> CIImage? {
        locker.object(forKey: #function).lock()
        defer {
            locker.object(forKey: #function).unlock()
        }
        guard let url = self.mediaURL else { return nil }
        return downsampleImage(url: url, renderSize: renderSize, renderScale: renderScale)
    }
    
    public func compositionImage(sourceFrame: CIImage, compositionTime: CMTime, renderSize: CGSize, renderScale: CGFloat, compensateTimeRange: CMTimeRange?) -> CIImage? {
        return process(image: sourceFrame, compositionTime: compositionTime, renderSize: renderSize, renderScale: renderScale, compensateTimeRange: compensateTimeRange)
    }
    
    func process(image: CIImage, compositionTime: CMTime, renderSize: CGSize, renderScale: CGFloat, compensateTimeRange: CMTimeRange?) -> CIImage {
        let actualRenderSize = renderSize.scaling(renderScale)
        var transform = CGAffineTransform.identity
        var frame = image
        do {
            frame = correctingTransform(image: frame, prefferdTransform: prefferdTransform)

            if var cropRect = cropedRect {
                let nw = cropRect.width
                let nh = cropRect.height
                let no = cropRect.origin

                if nw >= 1.0 && nh >= 1.0 && no == CGPoint(x: 0, y: 0) {
                    // 裁剪区域为原图大小区域，不做处理
                } else {
                    let width = frame.extent.width
                    let height = frame.extent.height

                    cropRect.size = CGSize(width: width * nw, height: height * nh)
                    cropRect.origin = CGPoint(x: width * no.x, y: height * no.y)
                    cropRect.origin.y = frame.extent.height - cropRect.origin.y - cropRect.height

                    frame = frame.cropped(to: cropRect)
                }
            }

            let moveFrameCenterToRenderRectOrigin = CGAffineTransform(translationX: -frame.extent.midX, y: -frame.extent.midY)
            transform = transform.concatenating(moveFrameCenterToRenderRectOrigin)
            defer {
                switch imageLayout {
                case .fit, .fill:
                    let moveFrameCenterToRenderRectCenter = CGAffineTransform(translationX: actualRenderSize.width / 2.0, y: actualRenderSize.height / 2.0)
                    transform = transform.concatenating(moveFrameCenterToRenderRectCenter)
                case .center(let point):
                    let center = CGPoint(x: point.x * actualRenderSize.width, y: point.y * actualRenderSize.height)
                    let translation = CGAffineTransform(translationX: center.x, y: center.y)
                    transform = transform.concatenating(translation)
                case .rect(let rect):
                    let point = rect.center
                    let center = CGPoint(x: point.x * actualRenderSize.width, y: point.y * actualRenderSize.height)
                    let translation = CGAffineTransform(translationX: center.x, y: center.y)
                    transform = transform.concatenating(translation)
                }
            }

            switch imageLayout {
            case .fit:
                let extent = frame.extent
                let widthRatio = actualRenderSize.width /  extent.width
                let heightRatio = actualRenderSize.height / extent.height
                let ratio: CGFloat = min(widthRatio, heightRatio)
                let scaleTransform = CGAffineTransform(scaleX: ratio, y: ratio)
                transform = transform.concatenating(scaleTransform)
                
            case .fill:
                let extent = frame.extent
                let widthRatio = actualRenderSize.width /  extent.width
                let heightRatio = actualRenderSize.height / extent.height
                let ratio: CGFloat = max(widthRatio, heightRatio)
                let scaleTransform = CGAffineTransform(scaleX: ratio, y: ratio)
                transform = transform.concatenating(scaleTransform)
                
            case .center(_):
                break
                
            case .rect(let rect):
                let extent = frame.extent
                let width = actualRenderSize.width * rect.width // 宽度，基于像素
                let height = actualRenderSize.height * rect.height // 高度，基于像素
                let scaleX = width / extent.size.width
                let scaleY = height / extent.size.height
                let scale = CGAffineTransform(scaleX: scaleX, y: scaleY)
                transform = transform.concatenating(scale)
            }
             
            if rotateRadian.isZero == false {
                let angle = -rotateRadian // 转为负数，变成顺时针旋转
                let rotationTransform = CGAffineTransform(rotationAngle: angle)
                transform = transform.concatenating(rotationTransform)
            }

            if isFlipHorizontal {
                let scale = CGAffineTransform(scaleX: -1, y: 1)
                transform = transform.concatenating(scale)
            }
        }

        if #available(iOS 10.0, *) {
            frame = frame.transformed(by: transform, highQualityDownsample: false)
        } else {
            frame = frame.transformed(by: transform)
        }
        
        if let lutImageURL = lutImageURL,
           let filterLutImage = self.image(url: lutImageURL, size: nil),
           filterIntensity.floatValue > 0.0
        {  // 查找表，添加滤镜
            let lutFilter = VCLutFilter.share
            lutFilter.inputIntensity = filterIntensity
            lutFilter.inputImage = frame
            lutFilter.lookupImage = filterLutImage
            if let outputImage = lutFilter.outputImage {
                frame = outputImage
            }
        }
        
        if let trajectory = trajectory {
            var timeRange = compensateTimeRange ?? self.timeRange
            let start = timeRange.start.seconds + TimeInterval(trajectory.range.left) * timeRange.duration.seconds
            let end = timeRange.start.seconds + TimeInterval(trajectory.range.right) * timeRange.duration.seconds
            timeRange = CMTimeRange(start: start, end: end)
            let progress = (compositionTime.seconds - timeRange.start.seconds) / timeRange.duration.seconds
            if progress.isInfinite == false, progress.isNaN == false {
                if let image = trajectory.transition(renderSize: actualRenderSize, progress: CGFloat(progress), image: frame) {
                    frame = image
                }
            }
        }
        
        if let canvasStyle = self.canvasStyle,
           let canvasImage = canvasImage(canvasStyle: canvasStyle, originImage: image, renderSize: renderSize, renderScale: renderScale)
        {
            frame = frame.composited(over: canvasImage)
        }
        
        return frame
    }
    
    func canvasImage(canvasStyle: VCCanvasStyle, originImage: CIImage, renderSize: CGSize, renderScale: CGFloat) -> CIImage? {
        var canvasImage: CIImage?
        
        switch canvasStyle {
        case .pureColor(let color):
            return VCHelper.image(color: color, size: renderSize.scaling(renderScale))
            
        case .image(let url):
            canvasImage = downsampleImage(url: url, renderSize: renderSize, renderScale: renderScale)
            
        case .blur:
            canvasImage = VCHelper.blurCompositing(inputImage: originImage)
        }
        
        if let canvasImage = canvasImage {
            var transform = CGAffineTransform.identity
            let moveFrameCenterToRenderRectOrigin = CGAffineTransform(translationX: -canvasImage.extent.midX, y: -canvasImage.extent.midY)
            transform = transform.concatenating(moveFrameCenterToRenderRectOrigin)
            
            let actualRenderSize = renderSize.scaling(renderScale)
            let extent = canvasImage.extent
            let widthRatio = actualRenderSize.width /  extent.width
            let heightRatio = actualRenderSize.height / extent.height
            let ratio: CGFloat = max(widthRatio, heightRatio)
            let scaleTransform = CGAffineTransform(scaleX: ratio, y: ratio)
            transform = transform.concatenating(scaleTransform)
            
            let moveFrameCenterToRenderRectCenter = CGAffineTransform(translationX: actualRenderSize.width / 2.0, y: actualRenderSize.height / 2.0)
            transform = transform.concatenating(moveFrameCenterToRenderRectCenter)
            
            return canvasImage.transformed(by: transform)
        } else {
            return nil
        }
    }
    
    func correctingTransform(image: CIImage, prefferdTransform optionalPrefferdTransform: CGAffineTransform?) -> CIImage {
        if var prefferdTransform = optionalPrefferdTransform {
            let extent = image.extent
            let transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: extent.origin.y * 2 + extent.height)
            prefferdTransform = transform.concatenating(prefferdTransform).concatenating(transform)
            return image.transformed(by: prefferdTransform)
        } else {
            return image
        }
    }
    
    func downsampleImage(url: URL, renderSize: CGSize, renderScale: CGFloat) -> CIImage? {
        let downsampleSize = self.downsampleSize(url: url, renderSize: renderSize, renderScale: renderScale)
        let image = self.image(url: url, size: downsampleSize)
        return image
    }
    
    /// 获取指定路径图片
    /// - Parameters:
    ///   - url: <#url description#>
    ///   - size: 图片的大小，不应该过大，否则可能会导致内存溢出。当size为nil，会将全尺寸的图片存在内存当中，当size不为nil，会根据size的大小，图片按比例缩放后存在内存当中
    /// - Returns: <#description#>
    func image(url: URL, size: CGSize?) -> CIImage? {
        let sizeIdentifier: String
        if let size = size {
            sizeIdentifier = "_size_" + size.debugDescription
        } else {
            sizeIdentifier = "_fullsize_"
        }
        let key = url.path + sizeIdentifier
        if let cacheImage = VCImageCache.share.ciImage(forKey: key) {
            return cacheImage
        } else {
            var optionalImage = CIImage(contentsOf: url)
            if let size = size, var frame = optionalImage {
                let widthRatio: CGFloat = size.width / frame.extent.width
                let heightRatio: CGFloat = size.height / frame.extent.height
                let scale = widthRatio < 1.0 ? widthRatio : heightRatio
                frame = frame.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                if let cgImage = CIContext.share.createCGImage(frame, from: CGRect(origin: .zero, size: frame.extent.size)) {
                    optionalImage = CIImage(cgImage: cgImage)
                }
            }
            VCImageCache.share.storeImage(toMemory: optionalImage, forKey: key)
            return optionalImage
        }
    }
    
    func downsampleSize(url: URL, renderSize: CGSize, renderScale: CGFloat) -> CGSize? {
        guard let imageSize = UIImage(contentsOfFile: url.path)?.size else { return nil }
        let scaleSize = renderSize.scaling(renderScale)
        if max(scaleSize.width, scaleSize.height) > max(imageSize.width, imageSize.height) {
            return imageSize
        } else {
            return scaleSize
        }
    }
    
}
