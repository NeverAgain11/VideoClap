//
//  CMTime.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

public extension CMTime {
    
    init(seconds: TimeInterval) {
        self.init(seconds: seconds, preferredTimescale: 600)
    }
    
    init(value: CMTimeValue) {
        self.init(value: value, timescale: 600)
    }
    
}
