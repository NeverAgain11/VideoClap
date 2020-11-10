//
//  VCDoorwayTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/5.
//

import Foundation
import CoreImage
import AVFoundation

open class VCDoorwayTransition: NSObject, VCTransitionProtocol {
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public var timeRange: CMTimeRange = .zero
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        
        let filter = VCDoorwayFilter()
        filter.inputTime = NSNumber(value: progress)
        filter.inputTargetImage = toImage
        filter.inputImage = fromImage
        
        if let image = filter.outputImage {
            finalImage = image
        }
        
        return finalImage
    }
    
}
