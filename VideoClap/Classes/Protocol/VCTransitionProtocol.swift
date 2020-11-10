//
//  VCTransitionProtocol.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/28.
//

import Foundation
import AVFoundation

public protocol VCTransitionProtocol: NSObject {
    
    var fromId: String { get set }
    
    var toId: String { get set }
    
    var timeRange: CMTimeRange { get set }
    
    func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage?
    
}
