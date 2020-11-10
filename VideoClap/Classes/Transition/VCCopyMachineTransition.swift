//
//  VCCopyMachineTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/29.
//

import Foundation
import AVFoundation
import CoreImage

open class VCCopyMachineTransition: NSObject, VCTransitionProtocol {
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public var timeRange: CMTimeRange = .zero
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        finalImage = copyMachineTransition(inputImage: fromImage,
                                           inputTargetImage: toImage,
                                           inputExtent: CIVector(cgRect: fromImage.extent),
                                           inputTime: NSNumber(value: progress),
                                           inputWidth: NSNumber(value: Float(fromImage.extent.width) * 0.2))
        return finalImage
    }
    
    func copyMachineTransition(inputImage: CIImage,
                               inputTargetImage: CIImage,
                               inputExtent: CIVector = CIVector(x: 0, y: 0, z: 300, w: 300),
                               inputColor: UIColor = UIColor.black,
                               inputTime: NSNumber = 0.00,
                               inputAngle: NSNumber = 0.00,
                               inputWidth: NSNumber = 200.00,
                               inputOpacity: NSNumber = 1.30) -> CIImage?
    {
        let filter = CIFilter(name: "CICopyMachineTransition")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(inputTargetImage, forKey: kCIInputTargetImageKey)
        
        filter.setValue(inputExtent, forKey: "inputExtent")
        filter.setValue(CIColor(color: inputColor), forKey: "inputColor")
        filter.setValue(inputAngle, forKey: kCIInputAngleKey)
        filter.setValue(inputWidth, forKey: kCIInputWidthKey)
        filter.setValue(inputOpacity, forKey: "inputOpacity")
        filter.setValue(inputTime, forKey: kCIInputTimeKey)
        
        return filter.outputImage
    }
    
}
