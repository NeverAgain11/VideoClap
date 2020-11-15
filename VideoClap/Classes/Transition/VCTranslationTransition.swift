//
//  VCTranslationTransition.swift
//  VideoClap
//
//  Created by laimincong on 2020/11/11.
//

import Foundation
import AVFoundation
import CoreImage

public enum TranslationType {
    case left
    case right
    case up
    case down
}

open class VCTranslationTransition: NSObject, VCTransitionProtocol {
    
    public var range: VCRange = VCRange(left: 0, right: 0)
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public var translation: CGFloat = 0.0
    
    public var translationType: TranslationType = .left
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        var transform = CGAffineTransform.identity
        switch translationType {
        case .left:
            transform = CGAffineTransform(translationX: translation * CGFloat(progress) * -1, y: 0)
        case .right:
            transform = CGAffineTransform(translationX: translation * CGFloat(progress) * 1, y: 0)
        case .up:
            transform = CGAffineTransform(translationX: 0.0, y: translation * CGFloat(progress) * -1)
        case .down:
            transform = CGAffineTransform(translationX: 0.0, y: translation * CGFloat(progress) * 1)
        }
        if let sourceOverImage = sourceOverCompositing(inputImage: fromImage.transformed(by: transform), inputBackgroundImage: toImage) {
            finalImage = sourceOverImage
        }
        return finalImage
    }
    
    func sourceOverCompositing(inputImage: CIImage, inputBackgroundImage: CIImage) -> CIImage? {
        let filter = CIFilter(name: "CISourceOverCompositing")!
        filter.setValue(inputImage, forKey: "inputImage")
        filter.setValue(inputBackgroundImage, forKey: "inputBackgroundImage")
        return filter.outputImage
    }
    
    public func config(closure: (VCTranslationTransition) -> Void) -> Self {
        closure(self)
        return self
    }
    
}
