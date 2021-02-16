//
//  VCGlitchTextEffect.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/16.
//

import Foundation

public class VCGlitchTextEffect: NSObject, VCTextEffectProviderProtocol {
    
    public var blendMode: CGBlendMode = .lighten
    
    public var alpha: Double = 0.8
    
    public var minOffsetX: CGFloat = 5.0
    
    public var maxOffsetX: CGFloat = 15.0
    
    public func effectImage(context: VCTextEffectRenderContext) -> CIImage? {
        if let textImage = textImage(context: context, rect: CGRect(origin: .zero, size: context.textSize)) {
            let image = compositionImage(originImage: textImage, random(), x2: random(), x3: random(), bounds: textImage.extent)
            
            return image
        }
        return nil
    }
    
    func textImage(context: VCTextEffectRenderContext, rect: CGRect) -> CIImage? {
        let renderer = VCGraphicsRenderer(rect.size)
        return renderer.ciImage { (_) in
            context.text.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: context.text.length))
            context.text.draw(at: .zero)
        }
    }
    
    func random() -> CGFloat {
        return CGFloat.random(in: minOffsetX...maxOffsetX)
    }
    
    func compositionImage(originImage: CIImage, _ x1: CGFloat, x2: CGFloat, x3: CGFloat, bounds: CGRect) -> CIImage {
        let redImage = originImage.withTintColor(.red)
        let blueImage = originImage.withTintColor(.blue)
        let greenImage = originImage.withTintColor(.green)
        
        let renderer = VCGraphicsRenderer(bounds)
        return renderer.ciImage { (_) in
            redImage.draw(in: bounds.add(CGRect(x: x1, y: 0, width: 0, height: 0)),
                          blendMode: blendMode,
                          alpha: CGFloat(alpha))
            greenImage.draw(in: bounds.add(CGRect(x: x2, y: 0, width: 0, height: 0)),
                            blendMode: blendMode,
                            alpha: CGFloat(alpha))
            blueImage.draw(in: bounds.add(CGRect(x: x3, y: 0, width: 0, height: 0)),
                           blendMode: blendMode,
                           alpha: CGFloat(alpha))
        } ?? originImage
    }
    
}
