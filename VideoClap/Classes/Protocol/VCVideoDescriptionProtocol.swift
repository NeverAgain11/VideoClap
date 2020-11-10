//
//  VCVideoDescriptionProtocol.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

public protocol VCVideoDescriptionProtocol: NSObject, NSCopying, NSMutableCopying {
    
    var renderSize: CGSize { get set }
    
    var renderScale: Float { get set }
    
    var fps: Double { get set }
    
    var mediaTracks: [VCTrackDescriptionProtocol] { get set }
    
}
