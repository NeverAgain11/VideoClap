//
//  VCDissolveTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/29.
//

import Foundation
import AVFoundation
import CoreImage

open class VCDissolveTransition: NSObject, VCTransitionProtocol {
    
    public var range: VCRange = VCRange(left: 0, right: 0)
    
    public var fromTrackVideoTransitionFrameClosure: (() -> CIImage?)?
    
    public var toTrackVideoTransitionFrameClosure: (() -> CIImage?)?
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        
        finalImage = dissolveTransition(inputImage: fromImage, inputTargetImage: toImage, inputTime: NSNumber(value: progress))
        
        return finalImage
    }
    
    func dissolveTransition(inputImage: CIImage, inputTargetImage: CIImage, inputTime: NSNumber = 0.0) -> CIImage? {
        let filter = CIFilter(name: "CIDissolveTransition")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(inputTargetImage, forKey: kCIInputTargetImageKey)
        filter.setValue(inputTime, forKey: kCIInputTimeKey)
        return filter.outputImage
    }
    
}

