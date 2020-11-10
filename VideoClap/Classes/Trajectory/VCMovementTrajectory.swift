//
//  VCMovementTrajectory.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/29.
//

import Foundation
import AVFoundation

public enum MovementType {
    case left
    case right
    case up
    case down
    case topLeft
    case bottomLeft
    case topRight
    case bottomRight
}

open class VCMovementTrajectory: NSObject, VCTrajectoryProtocol {
    
    public var id: String = ""
    
    public var timeRange: CMTimeRange = .zero
    
    public var movementType: MovementType = .bottomRight
    
    public var movementRatio: CGFloat = 1.0
    
    public func transition(renderSize: CGSize, progress: CGFloat, image: CIImage) -> CIImage? {
        var finalImage: CIImage?
        
        switch movementType {
        case .left:
            let moveDistance = image.extent.width * movementRatio
            let distance = progress * moveDistance
            finalImage = image.transformed(by: .init(translationX: -distance, y: 0))
            
        case .right:
            let moveDistance = image.extent.width * movementRatio
            let distance = progress * moveDistance
            finalImage = image.transformed(by: .init(translationX: distance, y: 0))
            
        case .up:
            let moveDistance = image.extent.height * movementRatio
            let distance = progress * moveDistance
            finalImage = image.transformed(by: .init(translationX: 0, y: distance))
            
        case .down:
            let moveDistance = image.extent.height * movementRatio
            let distance = progress * moveDistance
            finalImage = image.transformed(by: .init(translationX: 0, y: -distance))
            
        case .topLeft:
            let moveDistance = max(image.extent.width, image.extent.height) * movementRatio
            let distance = progress * moveDistance
            finalImage = image.transformed(by: .init(translationX: -distance, y: distance))
            
        case .bottomLeft:
            let moveDistance = max(image.extent.width, image.extent.height) * movementRatio
            let distance = progress * moveDistance
            finalImage = image.transformed(by: .init(translationX: -distance, y: -distance))
            
        case .topRight:
            let moveDistance = max(image.extent.width, image.extent.height) * movementRatio
            let distance = progress * moveDistance
            finalImage = image.transformed(by: .init(translationX: distance, y: distance))
            
        case .bottomRight:
            let moveDistance = max(image.extent.width, image.extent.height) * movementRatio
            let distance = progress * moveDistance
            finalImage = image.transformed(by: .init(translationX: distance, y: -distance))
        }
        
        return finalImage
    }
    
}
