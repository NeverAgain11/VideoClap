//
//  VCVortexTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/3.
//

import Foundation
import AVFoundation

public enum VCVortexTransitionSubType {
    case normal
    case single
}

open class VCVortexTransition: NSObject, VCTransitionProtocol {
    
    public var range: VCRange = VCRange(left: 0, right: 0)
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public var type: VCVortexTransitionSubType = .normal
    
    public var radiusRatio: Float = 5.0
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        
        switch type {
        case .normal :
            if progress < 0.5 {
                let center = CGPoint(x: fromImage.extent.midX, y: fromImage.extent.midY)
                let radius: Float = Float(CGFloat(progress) * fromImage.extent.width) * 1.2 * radiusRatio
                let angle: Float = Float(progress * 360.0) * 10.0
                if let image = vortexDistortionCompositing(inputImage: fromImage, inputCenter: CIVector(cgPoint: center), inputRadius: radius, inputAngle: angle) {
                    finalImage = image
                }
            } else {
                let center = CGPoint(x: toImage.extent.midX, y: toImage.extent.midY)
                let radius: Float = Float((1.0 - CGFloat(progress)) * toImage.extent.width) * 1.2 * radiusRatio
                let angle: Float = Float((1.0 - CGFloat(progress)) * 360.0) * 10.0
                if let image = vortexDistortionCompositing(inputImage: toImage, inputCenter: CIVector(cgPoint: center), inputRadius: radius, inputAngle: angle) {
                    finalImage = image
                }
            }
            
        case .single:
            let center = CGPoint(x: fromImage.extent.midX, y: fromImage.extent.midY)
            let radius: Float = Float(CGFloat(progress) * fromImage.extent.width) * 1.2 * radiusRatio
            let angle: Float = Float(progress * 260.0) * 5.0
            if let image = vortexDistortionCompositing(inputImage: fromImage, inputCenter: CIVector(cgPoint: center), inputRadius: radius, inputAngle: angle) {
                let alpha: CGFloat = CGFloat((1.0 - progress))
                
                finalImage = VCHelper.alphaCompositing(alphaValue: alpha, inputImage: image.composited(over: toImage))
            }
            
        }
        
        return finalImage
    }
    
    func vortexDistortionCompositing(inputImage: CIImage, inputCenter: CIVector = CIVector(x: 150, y: 150), inputRadius: Float = 300.00, inputAngle: Float = 56.55) -> CIImage? {
        let filter = CIFilter(name: "CIVortexDistortion")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(inputCenter, forKey: kCIInputCenterKey)
        filter.setValue(NSNumber(value: inputRadius), forKey: kCIInputRadiusKey)
        filter.setValue(NSNumber(value: inputAngle), forKey: kCIInputAngleKey)
        return filter.outputImage
    }
    
}
