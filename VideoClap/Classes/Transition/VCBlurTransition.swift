//
//  VCBlurTransition.swift
//  VideoClap
//
//  Created by 赖敏聪 on 2020/10/29.
//

import Foundation
import AVFoundation
import CoreImage

open class VCBlurTransition: NSObject, VCTransitionProtocol {
    
    /// default value is VCRange(left: 0, right: 0)
    public var range: VCRange = VCRange(left: 0, right: 0)
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    /// default value is 1000.0
    public var increasement: Float = 1000.0
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        
        if progress < 0.5 {
            if let slideImage = gaussianBlurCompositing(inputImage: fromImage, radius: NSNumber(value: progress * increasement)) {
                finalImage = slideImage
            }
        } else {
            if let slideImage = gaussianBlurCompositing(inputImage: toImage, radius: NSNumber(value: increasement - progress * increasement)) {
                finalImage = slideImage
            }
        }
        return finalImage
    }
    
    func gaussianBlurCompositing(inputImage: CIImage, radius: NSNumber) -> CIImage? {
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        return filter.outputImage
    }
    
}
