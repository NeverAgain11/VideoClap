//
//  VCBarsSwipeTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/29.
//

import Foundation
import AVFoundation
import CoreImage

open class VCBarsSwipeTransition: NSObject, VCTransitionProtocol {
    
    public var range: VCRange = VCRange(left: 0, right: 0)
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        finalImage = gaussianBlurCompositing(inputImage: fromImage,
                                             inputTargetImage: toImage,
                                             inputTime: NSNumber(value: progress))
        return finalImage
    }
    
    func gaussianBlurCompositing(inputImage: CIImage,
                                 inputTargetImage: CIImage,
                                 inputAngle: NSNumber =  3.14,
                                 inputWidth: NSNumber = 30.00,
                                 inputBarOffset: NSNumber = 10.00,
                                 inputTime: NSNumber = 0.00) -> CIImage?
    {
        let filter = CIFilter(name: "CIBarsSwipeTransition")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(inputTargetImage, forKey: kCIInputTargetImageKey)
        
        filter.setValue(inputAngle, forKey: kCIInputAngleKey)
        filter.setValue(inputWidth, forKey: kCIInputWidthKey)
        filter.setValue(inputBarOffset, forKey: "inputBarOffset")
        filter.setValue(inputTime, forKey: kCIInputTimeKey)
        
        return filter.outputImage
    }
    
}
