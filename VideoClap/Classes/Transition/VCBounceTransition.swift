//
//  VCBounceTransition.swift
//  VideoClap
//
//  Created by laimincong on 2020/11/13.
//

import Foundation
import AVFoundation

open class VCBounceTransition: NSObject, VCTransitionProtocol {
    
    public var range: VCRange = VCRange(left: 0, right: 0)
    
    public var fromTrackVideoTransitionFrameClosure: (() -> CIImage?)?
    
    public var toTrackVideoTransitionFrameClosure: (() -> CIImage?)?
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        
        let filter = VCBounceTransitionFilter()
        filter.inputImage = fromImage
        filter.inputTargetImage = toImage
        filter.inputTime = NSNumber(value: progress)
        filter.bounce = 3.2
        finalImage = filter.outputImage
        
        return finalImage
    }
    
}
