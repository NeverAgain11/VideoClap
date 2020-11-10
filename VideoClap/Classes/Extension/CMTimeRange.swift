//
//  CMTimeRange.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

extension CMTimeRange {
    
    public init(start: TimeInterval, end: TimeInterval) {
        self.init(start: CMTime(seconds: start), end: CMTime(seconds: end))
    }
    
    public init(start: TimeInterval, duration: TimeInterval) {
        self.init(start: CMTime(seconds: start), duration: CMTime(seconds: duration))
    }
    
    public var debugDescription: String {
        return "CMTimeRange(start: \(start.seconds), end: \(end.seconds), duration: \(duration.seconds))"
    }
    
}
