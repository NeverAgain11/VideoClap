//
//  VCWipeTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/28.
//

import Foundation
import AVFoundation
import CoreImage

public enum WipeType {
    case left
    case right
    case up
    case down
}

open class VCWipeTransition: NSObject, VCTransitionProtocol {
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public var timeRange: CMTimeRange = .zero
    
    public var wipeType: WipeType = .left
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        
        finalImage = wipeCompositing(inputImage: fromImage, inputBackgroundImage: toImage, wipeType: wipeType, ratio: CGFloat(progress), renderSize: renderSize)
        
        return finalImage
    }
    
    func wipeCompositing(inputImage: CIImage, inputBackgroundImage: CIImage, wipeType: WipeType, ratio: CGFloat, renderSize: CGSize) -> CIImage? {
        let videoBox = CGRect(origin: .zero, size: renderSize)
            
        var source = inputImage
        var source2 = inputBackgroundImage
        let dividedRect: (slice: CGRect, remainder: CGRect)
        switch wipeType {
        case .right:
            dividedRect = videoBox.divided(atDistance: videoBox.width * ratio, from: .minXEdge)
            
        case .left:
            dividedRect = videoBox.divided(atDistance: videoBox.width * ratio, from: .maxXEdge)
            
        case .up:
            dividedRect = videoBox.divided(atDistance: videoBox.width * ratio, from: .minYEdge)
            
        case .down:
            dividedRect = videoBox.divided(atDistance: videoBox.width * ratio, from: .maxYEdge)
        }
        source = source.cropped(to: dividedRect.remainder)
        source2 = source2.cropped(to: dividedRect.slice)
        return sourceOverCompositing(inputImage: source, inputBackgroundImage: source2)
    }
    
    func sourceOverCompositing(inputImage: CIImage, inputBackgroundImage: CIImage) -> CIImage? {
        let filter = CIFilter(name: "CISourceOverCompositing")!
        filter.setValue(inputImage, forKey: "inputImage")
        filter.setValue(inputBackgroundImage, forKey: "inputBackgroundImage")
        return filter.outputImage
    }
    
}
