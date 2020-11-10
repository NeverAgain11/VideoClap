//
//  VCSwirlTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/28.
//

import Foundation
import AVFoundation
import CoreImage

open class VCSwirlTransition: NSObject, VCTransitionProtocol {
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public var timeRange: CMTimeRange = .zero
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        let ratio: Float = progress * Float(renderSize.width)
        if let twirlImage = twirlDistortionCompositing(inputImage: fromImage, radius: NSNumber(value: ratio)) {
            finalImage = twirlImage
        }
        return finalImage
    }
    
    func twirlDistortionCompositing(inputImage: CIImage, radius: NSNumber) -> CIImage? {
        let twirlFilter = CIFilter(name: "CITwirlDistortion")!
        twirlFilter.setValue(inputImage, forKey: kCIInputImageKey)
        twirlFilter.setValue(radius, forKey: kCIInputRadiusKey)
        let x = inputImage.extent.midX
        let y = inputImage.extent.midY
        twirlFilter.setValue(CIVector(x: x, y: y), forKey: kCIInputCenterKey)
        return twirlFilter.outputImage
    }
    
}
