//
//  VCTrackDescriptionProtocol.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

public protocol VCTrackDescriptionProtocol: NSObject, NSCopying, NSMutableCopying {
    
    var id: String { get set }
    
    var trackType: VCTrackType { get set }
    
    var timeRange: CMTimeRange { get set }
    
    var prefferdTransform: CGAffineTransform? { get set }
    
    var mediaURL: URL? { get set }
    
    var mediaClipTimeRange: CMTimeRange { get set }
    
    var audioVolumeRampDescriptions: [VCAudioVolumeRampDescription] { get set }
    
    var imageClosure: (() -> CIImage?)? { get set }
    
}
