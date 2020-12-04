//
//  VCTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/22.
//

import AVFoundation

internal class VCTransition: NSObject {
    let transition: VCTransitionProtocol
    let timeRange: CMTimeRange
    var fromTrackClipTimeRange: CMTimeRange?
    var toTrackClipTimeRange: CMTimeRange?
    
    init(timeRange: CMTimeRange, transition: VCTransitionProtocol) {
        self.timeRange  = timeRange
        self.transition = transition
    }
}
