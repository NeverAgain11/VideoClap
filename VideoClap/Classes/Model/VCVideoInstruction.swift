//
//  VCVideoInstruction.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

internal class VCVideoInstruction: NSObject, AVVideoCompositionInstructionProtocol {
    
    let timeRange: CMTimeRange
    
    var enablePostProcessing: Bool = false
    
    var containsTweening: Bool = false
    
    var requiredSourceTrackIDs: [NSValue]? {
        return tracks.map({ $0.persistentTrackID }) as [NSValue]
    }
    
    var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    
    private(set) var tracks: [VCTrack] = []
    
    var videoProcessProtocol: VCVideoProcessProtocol?
    
//    var requestCallback: VCVideoCompositing.RequestCallback?
    
    init(timeRange: CMTimeRange, tracks: [VCTrack]) {
        self.tracks = tracks
        self.timeRange = timeRange
    }
    
}
