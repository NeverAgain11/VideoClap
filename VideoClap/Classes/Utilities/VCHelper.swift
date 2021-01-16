//
//  VCHelper.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/27.
//

import Foundation
import Metal

public class VCHelper: NSObject {
    
    internal static func bundle() -> Bundle {
        let bundleName: String = "VideoClap"
        var bundle: Bundle?
        if let url = Bundle.main.url(forResource: "Frameworks/\(bundleName).framework/\(bundleName).bundle", withExtension: nil) {
            bundle = Bundle(url: url)
        }
        if bundle == nil, let url = Bundle.main.url(forResource: bundleName, withExtension: "bundle") {
            bundle = Bundle(url: url)
        }
        return bundle ?? Bundle(for: VideoClap.self)
    }
    
    internal static func defaultMetallib() -> URL? {
        let bundleName: String = "VideoClap"
        var defaultMetallib: URL?
        
        if let frameworkUrl = Bundle.main.url(forResource: "Frameworks/\(bundleName).framework", withExtension: nil) {
            defaultMetallib = frameworkUrl.appendingPathComponent("default.metallib")
        }
        if defaultMetallib == nil, let url = Bundle.main.url(forResource: bundleName, withExtension: "bundle") {
            defaultMetallib = Bundle(url: url)?.url(forResource: "default", withExtension: "metallib")
        }
        return defaultMetallib
    }
    
    @available(iOS 11.0, *)
    internal static func kernel(functionName: String) -> CIKernel? {
        do {
            if let lib = VCHelper.defaultMetallib() {
                let data = try Data(contentsOf: lib)
                let kernel = try CIKernel(functionName: functionName, fromMetalLibraryData: data)
                return kernel
            } else {
                return nil
            }
        } catch let error {
            log.error(error)
            return nil
        }
    }
    
    public static func measure(fps: Bool = true) -> () -> TimeInterval {
        let start = CFAbsoluteTimeGetCurrent()
        return {
            if fps {
                return 1.0 / (CFAbsoluteTimeGetCurrent() - start)
            } else {
                return CFAbsoluteTimeGetCurrent() - start
            }
        }
    }
    
    public static func applyLutFilter(lutImageURL: URL, intensity: Float, at image: UIImage) -> UIImage? {
        let lutFilter = VCLutFilter()
        lutFilter.inputIntensity = NSNumber(value: intensity)
        
        if let ciImage = image.ciImage {
            lutFilter.inputImage = ciImage
        } else if let cgImage = image.cgImage {
            let ciImage = CIImage(cgImage: cgImage)
            lutFilter.inputImage = ciImage
        } else {
            return nil
        }
        
        let key = lutImageURL.path
        var lutImage: CIImage?
        
        if let image = VCImageCache.share.image(forKey: key) {
            lutImage = image
        } else {
            lutImage = CIImage(contentsOf: lutImageURL)
            VCImageCache.share.storeImage(toMemory: lutImage, forKey: key)
        }
        
        if let lutImage = lutImage {
            lutFilter.lookupImage = lutImage
        } else {
            return nil
        }
        
        if let outputImage = lutFilter.outputImage {
            return UIImage(ciImage: outputImage)
        } else {
            return nil
        }
    }
    
    static func image(color: UIColor, size: CGSize) -> CIImage {
        let key = "__custom_color_image" + size.debugDescription + color.debugDescription
        if let cacheImage = VCImageCache.share.image(forKey: key) {
            return cacheImage
        } else {
            let renderer = VCGraphicsRenderer()
            renderer.rendererRect.size = size
            let image = renderer.ciImage { (context) in
                UIColor.black.setFill()
                UIRectFill(renderer.rendererRect)
            }
            VCImageCache.share.storeImage(toMemory: image, forKey: key)
            return image ?? CIImage()
        }
    }
    
}

extension VCHelper {
    
    static func cropBusinessCardForPoints(image: CIImage, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
        
        var businessCard: CIImage
        businessCard = image.applyingFilter("CIPerspectiveTransformWithExtent",
                                            parameters: [
                                                "inputExtent": CIVector(cgRect: image.extent),
                                                "inputTopLeft": CIVector(cgPoint: topLeft),
                                                "inputTopRight": CIVector(cgPoint: topRight),
                                                "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                                                "inputBottomRight": CIVector(cgPoint: bottomRight)
                                            ])
        businessCard = image.cropped(to: businessCard.extent)
        
        return businessCard
    }
    
    static func sourceOverCompositing(inputImage: CIImage, inputBackgroundImage: CIImage) -> CIImage? {
        let filter = CIFilter(name: "CISourceOverCompositing")!
        filter.setValue(inputImage, forKey: "inputImage")
        filter.setValue(inputBackgroundImage, forKey: "inputBackgroundImage")
        return filter.outputImage
    }
    
    static func twirlDistortionCompositing(radius: CGFloat, inputImage: CIImage) -> CIImage? {
        let twirlFilter = CIFilter(name: "CITwirlDistortion")!
        twirlFilter.setValue(inputImage, forKey: kCIInputImageKey)
        twirlFilter.setValue(radius, forKey: kCIInputRadiusKey)
        let x = inputImage.extent.midX
        let y = inputImage.extent.midY
        twirlFilter.setValue(CIVector(x: x, y: y), forKey: kCIInputCenterKey)
        return twirlFilter.outputImage
    }
    
    static func maximumCompositing(inputImage: CIImage, inputBackgroundImage: CIImage) -> CIImage? {
        let combineFilter = CIFilter(name: "CIMaximumCompositing")!
        combineFilter.setValue(inputImage, forKey: kCIInputImageKey)
        combineFilter.setValue(inputBackgroundImage, forKey: kCIInputBackgroundImageKey)
        return combineFilter.outputImage
    }
    
    static func sourceAtopCompositing(inputImage: CIImage, inputBackgroundImage: CIImage) -> CIImage? {
        let combineFilter = CIFilter(name: "CISourceAtopCompositing")!
        combineFilter.setValue(inputImage, forKey: kCIInputImageKey)
        combineFilter.setValue(inputBackgroundImage, forKey: kCIInputBackgroundImageKey)
        return combineFilter.outputImage
    }
    
    static func minimumCompositing(inputImage: CIImage, inputBackgroundImage: CIImage) -> CIImage? {
        let combineFilter = CIFilter(name: "CIMinimumCompositing")!
        combineFilter.setValue(inputImage, forKey: kCIInputImageKey)
        combineFilter.setValue(inputBackgroundImage, forKey: kCIInputBackgroundImageKey)
        return combineFilter.outputImage
    }
    
    static func affineTransformCompositing(inputImage: CIImage, cgAffineTransform: CGAffineTransform) -> CIImage? {
        let filter = CIFilter(name: "CIAffineTransform")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(NSValue(cgAffineTransform: cgAffineTransform), forKey: kCIInputTransformKey)
        return filter.outputImage
    }
    
    static func lanczosScaleTransformCompositing(inputImage: CIImage, scale: Float, aspectRatio: Float) -> CIImage? {
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        filter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
        return filter.outputImage
    }
    
    static func alphaCompositing(alphaValue: CGFloat, inputImage: CIImage) -> CIImage? {
        guard let overlayFilter: CIFilter = CIFilter(name: "CIColorMatrix") else { return nil }
        let overlayRgba: [CGFloat] = [0, 0, 0, alphaValue]
        let alphaVector: CIVector = CIVector(values: overlayRgba, count: 4)
        overlayFilter.setValue(inputImage, forKey: kCIInputImageKey)
        overlayFilter.setValue(alphaVector, forKey: "inputAVector")
        return overlayFilter.outputImage
    }
    
}
