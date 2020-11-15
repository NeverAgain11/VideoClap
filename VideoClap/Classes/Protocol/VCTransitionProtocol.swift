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
    
    /// 只有当轨道不重叠，但是需要过渡动画的时候，这个属性才会起作用
    var range: VCRange { get set }
    
    func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage?
    
}
