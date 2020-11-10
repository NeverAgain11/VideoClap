//
//  VCIceMeltingTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/3.
//

import Foundation
import AVFoundation

open class VCIceMeltingTransition: NSObject, VCTransitionProtocol {
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public var timeRange: CMTimeRange = .zero
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        
        let filter = VCIceMeltingFilter()
        filter.inputImage = fromImage
        filter.inputTargetImage = toImage
        filter.inputTime = NSNumber(value: progress)
        
        finalImage = filter.outputImage
        
        return finalImage
    }
    
}
