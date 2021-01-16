//
//  VCTrajectoryProtocol.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/29.
//

import Foundation
import AVFoundation

public protocol VCTrajectoryProtocol: NSObject {
    
    var range: VCRange { get set }
    
    func transition(renderSize: CGSize, progress: CGFloat, image: CIImage) -> CIImage?
    
}
