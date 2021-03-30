//
//  VCTransitionProtocol.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/28.
//

import Foundation

public protocol VCTransitionProtocol: NSObject {
    
    func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage?
    
}
