//
//  VCScaleUpTrajectory.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/29.
//

import Foundation
import AVFoundation

open class VCScaleUpTrajectory: NSObject, VCTrajectoryProtocol {
    
    public var range: VCRange = .init(left: 0.0, right: 1.0)
    
    public var scale: CGFloat = -0.5
    
    public func transition(renderSize: CGSize, progress: CGFloat, image: CIImage) -> CIImage? {
        var finalImage: CIImage?
        let videoBox = CGRect(origin: .zero, size: renderSize)
        let aspectScale = 1 + (progress * scale)
        let scaleXY = CGAffineTransform(scaleX: aspectScale, y: aspectScale)
        let translate = CGAffineTransform(translationX: -videoBox.width / 2.0,
                                          y: -videoBox.height / 2.0)
        let translateToCenter = CGAffineTransform(translationX: videoBox.width / 2.0,
                                                  y: videoBox.height / 2.0)
        finalImage = image.transformed(by: translate).transformed(by: scaleXY).transformed(by: translateToCenter)
        
        return finalImage
    }
    
}
