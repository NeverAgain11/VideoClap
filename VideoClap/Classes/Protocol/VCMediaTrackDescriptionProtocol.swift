//
//  VCMediaTrackDescriptionProtocol.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/22.
//

import AVFoundation

public protocol VCMediaTrackDescriptionProtocol: VCTrackDescriptionProtocol {
    
    var id: String { get set }
    
    var timeRange: CMTimeRange { get set }
    
    var mediaClipTimeRange: CMTimeRange { get set }
    
    var mediaURL: URL? { get set }
    
}
