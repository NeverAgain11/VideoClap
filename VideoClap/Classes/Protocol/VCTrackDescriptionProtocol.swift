//
//  VCTrackDescriptionProtocol.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

public protocol Identifiable {
    
    var id: String { get set }
    
}

public protocol VCTrackDescriptionProtocol: NSCopying, NSMutableCopying, Identifiable {
    
    var timeRange: CMTimeRange { get set }
    
    func prepare(description: VCVideoDescription)
    
}

public protocol VCScaleTrackDescriptionProtocol: VCTrackDescriptionProtocol {
    
    var sourceTimeRange: CMTimeRange { get set }
    
    var timeMapping: CMTimeMapping { get set }
    
}

extension VCScaleTrackDescriptionProtocol {
    
    public var timeMapping: CMTimeMapping {
        get {
            return CMTimeMapping(source: sourceTimeRange, target: timeRange)
        }
        set {
            sourceTimeRange = newValue.source
            timeRange = newValue.target
        }
    }
    
}
