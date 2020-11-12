//
//  VCPageCurlWithShadowTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/29.
//

import Foundation
import AVFoundation
import CoreImage

open class VCPageCurlWithShadowTransition: NSObject, VCTransitionProtocol {
    
    public var range: VCRange = VCRange(left: 0, right: 0)
    
    public var fromTrackVideoTransitionFrameClosure: (() -> CIImage?)?
    
    public var toTrackVideoTransitionFrameClosure: (() -> CIImage?)?
    
    public var fromId: String = ""
    
    public var toId: String = ""

    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        
        finalImage = pageCurlWithShadowTransition(inputImage: fromImage,
                                                  inputTargetImage: toImage,
                                                  inputBacksideImage: fromImage,
                                                  inputExtent: CIVector(cgRect: fromImage.extent),
                                                  inputTime: NSNumber(value: progress),
                                                  inputAngle: NSNumber(value: 3.14 / 1.2))
        return finalImage
    }
    
    func pageCurlWithShadowTransition(inputImage: CIImage,
                                      inputTargetImage: CIImage,
                                      inputBacksideImage: CIImage,
                                      inputExtent: CIVector = CIVector(x: 0, y: 0, z: 0, w: 0),
                                      inputTime: NSNumber = 0.0,
                                      inputAngle: NSNumber = 0.0,
                                      inputRadius: NSNumber = 100.0,
                                      inputShadowSize: NSNumber = 0.50,
                                      inputShadowAmount: NSNumber = 0.70,
                                      inputShadowExtent: CIVector = CIVector(x: 0, y: 0, z: 0, w: 0)) -> CIImage?
    {
        let filter = CIFilter(name: "CIPageCurlWithShadowTransition")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(inputTargetImage, forKey: kCIInputTargetImageKey)
        filter.setValue(inputBacksideImage, forKey: "inputBacksideImage")
        filter.setValue(inputExtent, forKey: kCIInputExtentKey)
        filter.setValue(inputTime, forKey: kCIInputTimeKey)
        filter.setValue(inputAngle, forKey: kCIInputAngleKey)
        filter.setValue(inputRadius, forKey: kCIInputRadiusKey)
        filter.setValue(inputShadowSize, forKey: "inputShadowSize")
        filter.setValue(inputShadowAmount, forKey: "inputShadowAmount")
        filter.setValue(inputShadowExtent, forKey: "inputShadowExtent")
        return filter.outputImage
    }
    
}
