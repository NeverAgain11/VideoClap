//
//  VCSlideTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/28.
//

import Foundation
import AVFoundation
import CoreImage

open class VCSlideTransition: NSObject, VCTransitionProtocol {
    
    public var range: VCRange = VCRange(left: 0, right: 0)
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        if let slideImage = slideCompositing(leftImage: fromImage, rightImage: toImage, ratio: CGFloat(progress), renderSize: renderSize) {
            finalImage = slideImage
        }
        return finalImage
    }
    
    func slideCompositing(leftImage: CIImage, rightImage: CIImage, ratio: CGFloat, renderSize: CGSize) -> CIImage? {
        let videoBox = CGRect(origin: .zero, size: renderSize)
        let size = videoBox.size
        var tx1: CGFloat = 0.0
        var tx2: CGFloat = -size.width
        
        tx1 = 0.0 + ratio*size.width
        tx2 = -size.width + ratio*size.width
        
        let moveTransform1 = CGAffineTransform(a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: tx1, ty: 0.0)
        guard let output1 = affineTransformCompositing(inputImage: leftImage, cgAffineTransform: moveTransform1) else {
            return nil
        }
        let moveTransform2 = CGAffineTransform(a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: tx2, ty: 0.0)
        guard let output2 = affineTransformCompositing(inputImage: rightImage, cgAffineTransform: moveTransform2) else {
            return nil
        }
        return maximumCompositing(inputImage: output1, inputBackgroundImage: output2)
    }
    
    func affineTransformCompositing(inputImage: CIImage, cgAffineTransform: CGAffineTransform) -> CIImage? {
        let filter = CIFilter(name: "CIAffineTransform")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(NSValue(cgAffineTransform: cgAffineTransform), forKey: kCIInputTransformKey)
        return filter.outputImage
    }
    
    func maximumCompositing(inputImage: CIImage, inputBackgroundImage: CIImage) -> CIImage? {
        let filter = CIFilter(name: "CIMaximumCompositing")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(inputBackgroundImage, forKey: kCIInputBackgroundImageKey)
        return filter.outputImage
    }
    
}
