//
//  VCRotationTextEffect.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/14.
//

import Foundation

public enum RotationType {
    case custom(CGFloat)
    case autoRotate
    case rotate(CGFloat)
}

public class VCRotationTextEffect: NSObject, VCTextEffectProviderProtocol {
    
    private struct Items {
        var image: CIImage
        var character: SCTCharacter
    }
    
    public var rotationType: RotationType = .rotate(CGFloat.pi * 0.0)
    
    public init(rotationType: RotationType = .custom(0.0)) {
        super.init()
        self.rotationType = rotationType
    }
    
    public func effectImage(context: VCTextEffectRenderContext) -> CIImage? {
        var _angle: CGFloat = .zero
        switch rotationType {
        case .custom(let angle):
            _angle = angle
        case .autoRotate:
            _angle = CGFloat.pi * 2 * context.progress
        case .rotate(let speed):
            _angle = speed * context.progress
        }
        
        var images: [Items] = []
        for character in context.characters {
            let cgImage = image(of: character, angle: _angle)
            images.append(Items(image: cgImage, character: character))
        }
        
        return images.reduce(images.first?.image ?? CIImage()) { (reslut, item) -> CIImage in
            return reslut.composited(over: item.image)
        }
    }
    
    func image(of character: SCTCharacter, angle: CGFloat) -> CIImage {
        let renderer = VCGraphicsRenderer()
        renderer.rendererRect.size = character.character.size()
        
        var image = renderer.ciImage { (context) in
            character.character.draw(at: .zero)
        } ?? CIImage()
        var affineTransform = CGAffineTransform.identity
        affineTransform = affineTransform.concatenating(.init(rotationAngle: angle))
        affineTransform = affineTransform.concatenating(.init(translationX: character.frame.origin.x, y: character.frame.origin.y))
        
        image = image.transformed(by: affineTransform)
        return image
    }
    
    func rotateRect(_ rect: CGRect, angle: CGFloat) -> CGRect {
        let x = rect.midX
        let y = rect.midY
        let transform = CGAffineTransform(translationX: x, y: y)
                                        .rotated(by: angle)
                                        .translatedBy(x: -x, y: -y)
        return rect.applying(transform)
    }
    
}
