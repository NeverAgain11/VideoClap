//
//  VCHeartTransition.swift
//  VideoClap
//
//  Created by laimincong on 2020/11/12.
//

import Foundation
import AVFoundation
import CoreImage

open class VCHeartTransition: NSObject, VCTransitionProtocol {
    
    public var range: VCRange = VCRange(left: 0, right: 0)
    
    public var fromTrackVideoTransitionFrameClosure: (() -> CIImage?)?
    
    public var toTrackVideoTransitionFrameClosure: (() -> CIImage?)?
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        
        let filter = VCHeartFilter()
        filter.inputImage = fromImage
        filter.inputTargetImage = toImage
        filter.inputTime = NSNumber(value: progress)
        
        if let image = filter.outputImage {
            finalImage = image
        }
        
        return finalImage
    }
    
}
