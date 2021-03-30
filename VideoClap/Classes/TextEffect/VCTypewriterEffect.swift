//
//  VCTypewriterEffect.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/14.
//

import Foundation
import simd

open class VCTypewriterEffect: NSObject, VCTextEffectProviderProtocol {
    
    public var isFadeIn: Bool = false
    
    open func effectImage(context: VCTextEffectRenderContext) -> CIImage? {
        let length = CGFloat(context.text.length) * context.progress
        let textRange = NSRange(location: 0, length: Int(length))
        if textRange.length == .zero {
            return nil
        }
        let renderText = context.text.attributedSubstring(from: textRange).mutableCopy() as! NSMutableAttributedString
        
        if isFadeIn {
            let alpha = simd_fract(Float(length))
            var foregroundColor: UIColor = (renderText.attribute(.foregroundColor, at: renderText.length - 1, effectiveRange: nil) as? UIColor) ?? .black
            foregroundColor = foregroundColor.withAlphaComponent(CGFloat(alpha))
            renderText.addAttribute(.foregroundColor, value: foregroundColor, range: NSRange(location: renderText.length - 1, length: 1))
        }
        
        let renderer = VCGraphicsRenderer()
        renderer.rendererRect.size = context.textSize
        
        return renderer.ciImage { (_) in
            renderText.draw(at: .zero)
        }
    }
    
}
