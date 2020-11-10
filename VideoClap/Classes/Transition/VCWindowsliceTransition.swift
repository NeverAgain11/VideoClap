//
//  VCWindowsliceTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/5.
//

import Foundation
import AVFoundation
import CoreImage

open class VCWindowsliceTransition: NSObject, VCTransitionProtocol {
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public var timeRange: CMTimeRange = .zero
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        
        let filter = VCWindowsliceFilter()
        filter.inputImage = fromImage
        filter.inputTargetImage = toImage
        filter.inputTime = NSNumber(value: progress)
        
        if let image = filter.outputImage {
            finalImage = image
        }
        
        return finalImage
    }
    
}

