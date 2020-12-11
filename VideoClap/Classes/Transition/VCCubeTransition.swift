//
//  VCCubeTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/11.
//

import AVFoundation

public class VCCubeTransition: NSObject, VCTransitionProtocol {
    
    public var range: VCRange = VCRange(left: 0, right: 0)
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        
        let filter = VCCubeFilter()
        filter.inputTime = NSNumber(value: progress)
        filter.inputImage = fromImage
        filter.inputTargetImage = toImage
        
        if let image = filter.outputImage {
            finalImage = image
        }
        
        return finalImage
    }
    
}
