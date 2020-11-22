//
//  VCTrackDescriptionProtocol.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

public protocol VCTrackDescriptionProtocol: NSCopying, NSMutableCopying {
    
    var id: String { get set }
    
    var timeRange: CMTimeRange { get set }
    
}
