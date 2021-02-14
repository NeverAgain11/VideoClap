//
//  VCGraphicsRenderer.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/10.
//

import Foundation

public class VCGraphicsRenderer: NSObject {
    
    public var rendererRect: CGRect = .zero
    
    public var scale: CGFloat = 1.0
    
    public var opaque: Bool = false
    
    public func jpegData(withCompressionQuality compressionQuality: CGFloat, flipY: Bool = false, actions: (CGContext) -> Void) -> Data? {
        return self.image(flipY: flipY, actions: actions)?.jpegData(compressionQuality: compressionQuality)
    }
    
    public func pngData(flipY: Bool = false, actions: (CGContext) -> Void) -> Data? {
        return self.image(flipY: flipY, actions: actions)?.pngData()
    }
    
    public func image(flipY: Bool = false, actions: (CGContext) -> Void) -> UIImage? {
        if #available(iOS 10.0, *) {
            let format = UIGraphicsImageRendererFormat()
            format.opaque = opaque
            format.scale = scale
            let renderer = UIGraphicsImageRenderer(size: rendererRect.size, format: format)
            let image = renderer.image { (context) in
                if flipY {
                    context.cgContext.textMatrix = .identity
                    context.cgContext.translateBy(x: 0, y: rendererRect.size.height)
                    context.cgContext.scaleBy(x: 1.0, y: -1.0)
                }
                actions(context.cgContext)
            }
            return image
        } else {
            UIGraphicsBeginImageContextWithOptions(rendererRect.size, opaque, scale)
            defer {
                UIGraphicsEndImageContext()
            }
            
            if let cgContext = UIGraphicsGetCurrentContext() {
                if flipY {
                    cgContext.textMatrix = .identity
                    cgContext.translateBy(x: 0, y: rendererRect.size.height)
                    cgContext.scaleBy(x: 1.0, y: -1.0)
                }
                actions(cgContext)
                if let currentImage = UIGraphicsGetImageFromCurrentImageContext() {
                    return currentImage
                }
            }
        }
        return nil
    }
    
    public func ciImage(options: [CIImageOption : Any]? = nil, flipY: Bool = false, actions: (CGContext) -> Void) -> CIImage? {
        if let uiImage = image(flipY: flipY, actions: actions) {
            return CIImage(image: uiImage, options: options)
        } else {
            return nil
        }
    }
    
    public func cgImage(flipY: Bool = false, actions: (CGContext) -> Void) -> CGImage? {
        return self.image(flipY: flipY, actions: actions)?.cgImage
    }
    
}
