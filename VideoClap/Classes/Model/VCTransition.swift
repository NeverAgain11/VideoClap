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
    
    /// 指示两个轨道是否重叠
    var isOverlay: Bool = false
    
    init(timeRange: CMTimeRange, transition: VCTransitionProtocol) {
        self.timeRange = timeRange
        self.transition = transition
    }
}
