//
//  VCWaveTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/2.
//

import AVFoundation

open class VCWaveTransition: NSObject, VCTransitionProtocol {
    
    public var range: VCRange = VCRange(left: 0, right: 0)
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        
        let filter = VCWaveFilter()
        filter.inputImage = fromImage
        filter.inputTargetImage = toImage
        filter.inputTime = NSNumber(value: progress)
        filter.renderSize = CIVector(x: renderSize.width, y: renderSize.height)
        finalImage = filter.outputImage
        
        return finalImage
    }
    
}
