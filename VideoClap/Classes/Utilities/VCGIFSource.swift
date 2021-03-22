//
//  VCGIFSource.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/26.
//

import AVFoundation
import Accelerate

public class VCGIFSource: NSObject, NSCopying, NSMutableCopying {
    
    public let url: URL
    
    public var frameCount: Int = 0
    
    public private(set) var imageSource: CGImageSource?
    
    public private(set) var frameProperties: [[CFString:Any]] = []
    
    public private(set) var duration: CMTime = .zero
    
    public private(set) var width: CGFloat = .zero
    
    public private(set) var height: CGFloat = .zero
    
    public init(url: URL) {
        self.url = url
        super.init()
        
        if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) {
            self.imageSource = imageSource
        }
    }
    
    public func loadProperties() {
        frameProperties = []
        guard let imageSource = self.imageSource else { return }
        frameCount = CGImageSourceGetCount(imageSource)
        duration = .zero
        
        if frameCount > 0 {
            let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString:Any]
            let width: Int = properties?[kCGImagePropertyPixelWidth] as? Int ?? 0
            let height: Int = properties?[kCGImagePropertyPixelHeight] as? Int ?? 0
            self.width = CGFloat(width)
            self.height = CGFloat(height)
        }
        
        for index in 0..<frameCount {
            if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) as? [CFString:Any] {
                
                if let frameProperty = properties[kCGImagePropertyGIFDictionary] as? [CFString:Any] {
                    frameProperties.append(frameProperty)
                    
                    if let duration = (frameProperty[kCGImagePropertyGIFUnclampedDelayTime] ?? frameProperty[kCGImagePropertyGIFDelayTime]) as? TimeInterval {
                        self.duration = self.duration + CMTime(seconds: duration, preferredTimescale: 600)
                    }
                }
            }
        }
    }
    
    public func loopImage(at time: CMTime) -> CIImage? {
        let progress = CGFloat(time.seconds.truncatingRemainder(dividingBy: duration.seconds)).map(from: 0...CGFloat(duration.seconds), to: 0...1)
        if progress.isNaN || progress.isInfinite {
            return nil
        }
        let _time = CMTime(seconds: duration.seconds * TimeInterval(progress), preferredTimescale: 600)
        return self.image(at: _time)
    }
    
    public func image(at time: CMTime) -> CIImage? {
        guard let imageSource = self.imageSource else { return nil }
        let _time = CMTimeClampToRange(time, range: CMTimeRange(start: .zero, duration: duration))
        let per = _time.seconds / duration.seconds
        if per.isNaN || per.isInfinite {
            return nil
        }
        var index = Int(TimeInterval(frameCount) * per)
        index.clamping(to: 0..<frameCount)
        let key = self.url.path + "_GIF_" + String(index)
        if let cacheImage = VCImageCache.share.ciImage(forKey: key) {
            return cacheImage
        } else {
            if let cgImage = CGImageSourceCreateImageAtIndex(imageSource, index, nil) {
                let ciImage = CIImage(cgImage: cgImage)
                VCImageCache.share.storeImage(toMemory: ciImage, forKey: key)
                return ciImage
            }
        }
        return nil
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCGIFSource(url: self.url)
        copyObj.frameCount = frameCount
        copyObj.imageSource = imageSource
        copyObj.frameProperties = frameProperties
        copyObj.duration = duration
        copyObj.width = width
        copyObj.height = height
        return copyObj
    }
    
}
