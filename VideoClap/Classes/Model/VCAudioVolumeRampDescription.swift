//
//  VCAudioVolumeRampDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

public struct VCAudioVolumeRampDescription {
    public var startVolume: Float
    public var endVolume: Float
    public var timeRange: CMTimeRange
    
    public init(startVolume: Float, endVolume: Float, timeRange: CMTimeRange) {
        self.startVolume = startVolume
        self.endVolume = endVolume
        self.timeRange = timeRange
    }
}
