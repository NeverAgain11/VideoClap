//
//  VCFlipTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/28.
//

import Foundation
import AVFoundation
import CoreImage

open class VCFlipTransition: NSObject, VCTransitionProtocol {
    
    public var range: VCRange = VCRange(left: 0, right: 0)
    
    public var fromTrackVideoTransitionFrameClosure: (() -> CIImage?)?
    
    public var toTrackVideoTransitionFrameClosure: (() -> CIImage?)?
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    public func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        var finalImage: CIImage?
        let thresholdValue: CGFloat = 0.5
        if CGFloat(progress) < thresholdValue {
            let scaleX: CGFloat = CGFloat(1 - progress.map(from: 0.0...0.5, to: 0.0...1.0))
            if let flipImage = flipCompositing(inputImage: fromImage, scaleX: scaleX, renderSize: renderSize) {
                finalImage = flipImage
            }
        } else {
            let scaleX: CGFloat = CGFloat(progress.map(from: 0.5...1.0, to: 0.0...1.0))
            if let flipImage = flipCompositing(inputImage: toImage, scaleX: scaleX, renderSize: renderSize) {
                finalImage = flipImage
            }
        }
        return finalImage
    }
    
    func flipCompositing(inputImage: CIImage, scaleX: CGFloat, renderSize: CGSize) -> CIImage? {
        let videoBox = CGRect(origin: .zero, size: renderSize)
        let scale = CGAffineTransform(scaleX: scaleX, y: 1)
        let translate = CGAffineTransform(translationX: -videoBox.width / 2.0,
                                          y: -videoBox.height / 2.0)
        let translateToCenter = CGAffineTransform(translationX: videoBox.width / 2.0,
                                                  y: videoBox.height / 2.0)
        var source = inputImage
        source = source.transformed(by: translate).transformed(by: scale).transformed(by: translateToCenter)
        return source
    }
    
}
