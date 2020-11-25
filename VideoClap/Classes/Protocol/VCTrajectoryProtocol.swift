//
//  VCTrajectoryProtocol.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/29.
//

import Foundation
import AVFoundation

public protocol VCTrajectoryProtocol: NSObject {
    
    var id: String { get set }
    
    var timeRange: CMTimeRange { get set }
    
    var associationInfo: TrajectoryAssociationInfo { get set }
    
    func transition(renderSize: CGSize, progress: CGFloat, image: CIImage) -> CIImage?
    
}

public class TrajectoryAssociationInfo: NSObject {
    
    internal var fixClipTimeRange: CMTimeRange?
    
}

internal extension VCTrajectoryProtocol {
    internal var fixClipTimeRange: CMTimeRange? {
        get { return associationInfo.fixClipTimeRange }
        set { associationInfo.fixClipTimeRange = newValue }
    }
}
