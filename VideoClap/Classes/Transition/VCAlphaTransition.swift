//
//  VCAlphaTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/28.
//

import Foundation
import AVFoundation
import CoreImage

public enum FadeType {
    case `in`
    case out
}

open class VCAlphaTransition: NSObject, VCTransitionProtocol {
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public var timeRange: CMTimeRange = .zero
    
    public var fadeType: FadeType = .out
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        
        switch fadeType {
        case .in:
            if let alphaCompositingImage = alphaCompositing(inputImage: fromImage, alphaValue: CGFloat(1 - progress)),
                let sourceOverImage = sourceOverCompositing(inputImage: alphaCompositingImage, inputBackgroundImage: toImage)
            {
                finalImage = sourceOverImage
            }
        case .out:
            if let alphaCompositingImage = alphaCompositing(inputImage: toImage, alphaValue: CGFloat(progress)),
                let sourceOverImage = sourceOverCompositing(inputImage: alphaCompositingImage, inputBackgroundImage: fromImage)
            {
                finalImage = sourceOverImage
            }
        }
        
        return finalImage
    }
    
    func alphaCompositing(inputImage: CIImage, alphaValue: CGFloat) -> CIImage? {
        guard let overlayFilter: CIFilter = CIFilter(name: "CIColorMatrix") else { return nil }
        let overlayRgba: [CGFloat] = [0, 0, 0, alphaValue]
        let alphaVector: CIVector = CIVector(values: overlayRgba, count: 4)
        overlayFilter.setValue(inputImage, forKey: kCIInputImageKey)
        overlayFilter.setValue(alphaVector, forKey: "inputAVector")
        return overlayFilter.outputImage
    }
    
    func sourceOverCompositing(inputImage: CIImage, inputBackgroundImage: CIImage) -> CIImage? {
        let filter = CIFilter(name: "CISourceOverCompositing")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(inputBackgroundImage, forKey: kCIInputBackgroundImageKey)
        return filter.outputImage
    }
    
}
