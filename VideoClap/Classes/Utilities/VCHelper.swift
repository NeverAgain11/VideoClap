//
//  VCHelper.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/27.
//

import Foundation
import Metal
import AVFoundation

public class VCHelper: NSObject {
    
    internal static func runInMainThread(_ closure: @escaping () -> Void) {
        if Thread.current.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async {
                closure()
            }
        }
    }
    
    internal static func bundle() -> Bundle {
        let bundleName: String = "VideoClap"
        return bundle(bundleName: bundleName)
    }
    
    internal static func bundle(bundleName: String) -> Bundle {
        var bundle: Bundle?
        if let url = Bundle.main.url(forResource: "Frameworks/\(bundleName).framework/\(bundleName).bundle", withExtension: nil) {
            bundle = Bundle(url: url)
        }
        if bundle == nil, let url = Bundle.main.url(forResource: bundleName, withExtension: "bundle") {
            bundle = Bundle(url: url)
        }
        return bundle ?? Bundle(for: VideoClap.self)
    }
    
    internal static func metalLibURL(name: String) -> URL? {
        return bundle().url(forResource: name, withExtension: "metallib")
    }
    
    internal static func defaultMetalLibURL() -> URL? {
        return self.metalLibURL(name: "default")
    }
    
    @available(iOS 11.0, *)
    internal static func kernel(functionName: String) -> CIKernel? {
        do {
            if let url = bundle().url(forResource: functionName, withExtension: "ci.metallib") {
                let data = try Data(contentsOf: url)
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
        let lutFilter = VCLutFilter.share
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
        
        if let image = VCImageCache.share.ciImage(forKey: key) {
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
        if let cacheImage = VCImageCache.share.ciImage(forKey: key) {
            return cacheImage
        } else {
            let renderer = VCGraphicsRenderer()
            renderer.rendererRect.size = size
            let image = renderer.ciImage { (context) in
                color.setFill()
                UIRectFill(renderer.rendererRect)
            }
            VCImageCache.share.storeImage(toMemory: image, forKey: key)
            return image ?? CIImage()
        }
    }
    
    public static func listPropertiesNames(type: AnyClass) -> [String] {
        var propertyNames: [String] = []
        var count = UInt32()
        let classToInspect: AnyClass = type
        let properties: UnsafeMutablePointer<objc_property_t>? = class_copyPropertyList(classToInspect, &count)
        
        let intCount = Int(count)
        for i in 0..<intCount {
            guard let property = properties?[i] else {
                return []
            }
            guard let propertyName = NSString(utf8String: property_getName(property)) as String? else {
                return []
            }

            propertyNames.append(propertyName)
        }

        free(properties)
        return propertyNames
    }
    
    public static func audioError(_ error: OSStatus) -> NSError? {
        switch error {
        case kAudioUnitErr_InvalidProperty:
            return NSError(domain: "", code: Int(kAudioUnitErr_InvalidProperty), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_InvalidProperty"])
        case kAudioUnitErr_InvalidParameter:
            return NSError(domain: "", code: Int(kAudioUnitErr_InvalidParameter), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_InvalidParameter"])
        case kAudioUnitErr_InvalidElement:
            return NSError(domain: "", code: Int(kAudioUnitErr_InvalidElement), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_InvalidElement"])
        case kAudioUnitErr_NoConnection:
            return NSError(domain: "", code: Int(kAudioUnitErr_NoConnection), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_NoConnection"])
        case kAudioUnitErr_FailedInitialization:
            return NSError(domain: "", code: Int(kAudioUnitErr_FailedInitialization), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_FailedInitialization"])
        case kAudioUnitErr_TooManyFramesToProcess:
            return NSError(domain: "", code: Int(kAudioUnitErr_TooManyFramesToProcess), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_TooManyFramesToProcess"])
        case kAudioUnitErr_InvalidFile:
            return NSError(domain: "", code: Int(kAudioUnitErr_InvalidFile), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_InvalidFile"])
        case kAudioUnitErr_UnknownFileType:
            return NSError(domain: "", code: Int(kAudioUnitErr_UnknownFileType), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_UnknownFileType"])
        case kAudioUnitErr_FileNotSpecified:
            return NSError(domain: "", code: Int(kAudioUnitErr_FileNotSpecified), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_FileNotSpecified"])
        case kAudioUnitErr_FormatNotSupported:
            return NSError(domain: "", code: Int(kAudioUnitErr_FormatNotSupported), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_FormatNotSupported"])
        case kAudioUnitErr_Uninitialized:
            return NSError(domain: "", code: Int(kAudioUnitErr_Uninitialized), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_Uninitialized"])
        case kAudioUnitErr_InvalidScope:
            return NSError(domain: "", code: Int(kAudioUnitErr_InvalidScope), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_InvalidScope"])
        case kAudioUnitErr_PropertyNotWritable:
            return NSError(domain: "", code: Int(kAudioUnitErr_PropertyNotWritable), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_PropertyNotWritable"])
        case kAudioUnitErr_CannotDoInCurrentContext:
            return NSError(domain: "", code: Int(kAudioUnitErr_CannotDoInCurrentContext), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_CannotDoInCurrentContext"])
        case kAudioUnitErr_InvalidPropertyValue:
            return NSError(domain: "", code: Int(kAudioUnitErr_InvalidPropertyValue), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_InvalidPropertyValue"])
        case kAudioUnitErr_PropertyNotInUse:
            return NSError(domain: "", code: Int(kAudioUnitErr_PropertyNotInUse), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_PropertyNotInUse"])
        case kAudioUnitErr_Initialized:
            return NSError(domain: "", code: Int(kAudioUnitErr_Initialized), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_Initialized"])
        case kAudioUnitErr_InvalidOfflineRender:
            return NSError(domain: "", code: Int(kAudioUnitErr_InvalidOfflineRender), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_InvalidOfflineRender"])
        case kAudioUnitErr_Unauthorized:
            return NSError(domain: "", code: Int(kAudioUnitErr_Unauthorized), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_Unauthorized"])
        case kAudioUnitErr_MIDIOutputBufferFull:
            return NSError(domain: "", code: Int(kAudioUnitErr_MIDIOutputBufferFull), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_MIDIOutputBufferFull"])
        case kAudioComponentErr_InstanceTimedOut:
            return NSError(domain: "", code: Int(kAudioComponentErr_InstanceTimedOut), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioComponentErr_InstanceTimedOut"])
        case kAudioComponentErr_InstanceInvalidated:
            return NSError(domain: "", code: Int(kAudioComponentErr_InstanceInvalidated), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioComponentErr_InstanceInvalidated"])
        case kAudioUnitErr_RenderTimeout:
            return NSError(domain: "", code: Int(kAudioUnitErr_RenderTimeout), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_RenderTimeout"])
        case kAudioUnitErr_ExtensionNotFound:
            return NSError(domain: "", code: Int(kAudioUnitErr_ExtensionNotFound), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_ExtensionNotFound"])
        case kAudioUnitErr_InvalidParameterValue:
            return NSError(domain: "", code: Int(kAudioUnitErr_InvalidParameterValue), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_InvalidParameterValue"])
        case kAudioUnitErr_InvalidFilePath:
            return NSError(domain: "", code: Int(kAudioUnitErr_InvalidFilePath), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_InvalidFilePath"])
        case kAudioUnitErr_MissingKey:
            return NSError(domain: "", code: Int(kAudioUnitErr_MissingKey), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_MissingKey"])
        case kAudio_UnimplementedError:
            return NSError(domain: "", code: Int(kAudio_UnimplementedError), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudio_UnimplementedError"])
        case kAudio_FileNotFoundError:
            return NSError(domain: "", code: Int(kAudio_FileNotFoundError), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudio_FileNotFoundError"])
        case kAudio_FilePermissionError:
            return NSError(domain: "", code: Int(kAudio_FilePermissionError), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudio_FilePermissionError"])
        case kAudio_TooManyFilesOpenError:
            return NSError(domain: "", code: Int(kAudio_TooManyFilesOpenError), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudio_TooManyFilesOpenError"])
        case kAudio_BadFilePathError:
            return NSError(domain: "", code: Int(kAudio_BadFilePathError), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudio_BadFilePathError"])
        case kAudio_ParamError:
            return NSError(domain: "", code: Int(kAudio_ParamError), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudio_ParamError"])
        case kAudio_MemFullError:
            return NSError(domain: "", code: Int(kAudio_MemFullError), userInfo: [NSLocalizedFailureReasonErrorKey:"kAudio_MemFullError"])
        case noErr:
            return nil
        default:
            return NSError(domain: "", code: -1, userInfo: [NSLocalizedFailureReasonErrorKey:"kAudioUnitErr_Unknow"])
        }
    }
    
    public static func active() {
        guard AVAudioSession.sharedInstance().category != .playback else {
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch let error {
            debugPrint(error.localizedDescription)
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
    
    static func blurCompositing(value: CGFloat = 10.0, inputImage: CIImage) -> CIImage? {
        guard let filter: CIFilter = CIFilter(name: "CIBoxBlur") else { return nil }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(NSNumber(value: Float(value)), forKey: kCIInputRadiusKey)
        return filter.outputImage
    }
    
}
