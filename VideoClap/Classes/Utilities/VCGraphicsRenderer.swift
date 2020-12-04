//
//  VCGraphicsRenderer.swift
//  VideoClap
//
//  Created by laimincong on 2020/11/10.
//

import Foundation

public class VCGraphicsRenderer: NSObject {
    
    public var rendererRect: CGRect = .zero
    
    public var scale: CGFloat = 1.0
    
    public var opaque: Bool = false
    
    public func jpegData(withCompressionQuality compressionQuality: CGFloat, actions: (CGContext) -> Void) -> Data? {
        return self.image(actions: actions)?.jpegData(compressionQuality: compressionQuality)
    }
    
    public func pngData(actions: (CGContext) -> Void) -> Data? {
        return self.image(actions: actions)?.pngData()
    }
    
    public func image(actions: (CGContext) -> Void) -> UIImage? {
        if #available(iOS 10.0, *) {
            let format = UIGraphicsImageRendererFormat()
            format.opaque = opaque
            format.scale = scale
            let renderer = UIGraphicsImageRenderer(size: rendererRect.size, format: format)
            let image = renderer.image { (context) in
                actions(context.cgContext)
            }
            return image
        } else {
            UIGraphicsBeginImageContextWithOptions(rendererRect.size, opaque, scale)
            defer {
                UIGraphicsEndImageContext()
            }
            
            if let cgContext = UIGraphicsGetCurrentContext() {
                actions(cgContext)
                if let currentImage = UIGraphicsGetImageFromCurrentImageContext() {
                    return currentImage
                }
            }
        }
        return nil
    }
    
    public func ciImage(options: [CIImageOption : Any]? = nil, actions: (CGContext) -> Void) -> CIImage? {
        if let uiImage = image(actions: actions) {
            return CIImage(image: uiImage, options: options)
        } else {
            return nil
        }
    }
    
    public func cgImage(actions: (CGContext) -> Void) -> CGImage? {
        return self.image(actions: actions)?.cgImage
    }
    
}
