//
//  VCModTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/4.
//

import Foundation
import AVFoundation
import CoreImage

open class VCModTransition: NSObject, VCTransitionProtocol {
    
    public var range: VCRange = VCRange(left: 0, right: 0)
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        
        if let image = modTransition(inputImage: fromImage,
                                     inputTargetImage: toImage,
                                     inputCenter: CIVector(x: renderSize.width / 2.0, y: renderSize.height / 2.0),
                                     inputTime: NSNumber(value: progress))
        {
            finalImage = image
        }
        
        return finalImage
    }
    
    func modTransition(inputImage: CIImage,
                       inputTargetImage: CIImage,
                       inputCenter: CIVector = CIVector(x: 150, y: 150),
                       inputTime: NSNumber = 0.0,
                       inputAngle: NSNumber = 2.0,
                       inputRadius: NSNumber = 150.0,
                       inputCompression: NSNumber = 300.0) -> CIImage?
    {
        let filter = CIFilter(name: "CIModTransition")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(inputTargetImage, forKey: kCIInputTargetImageKey)
        filter.setValue(inputCenter, forKey: kCIInputCenterKey)
        filter.setValue(inputTime, forKey: kCIInputTimeKey)
        filter.setValue(inputAngle, forKey: kCIInputAngleKey)
        filter.setValue(inputRadius, forKey: kCIInputRadiusKey)
        filter.setValue(inputCompression, forKey: "inputCompression")
        return filter.outputImage
    }
    
}
