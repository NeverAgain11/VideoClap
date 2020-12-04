//
//  VCVideoInstruction.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

internal class VCVideoInstruction: NSObject, AVVideoCompositionInstructionProtocol {
    
    var timeRange: CMTimeRange = .zero
    
    var enablePostProcessing: Bool = false
    
    var containsTweening: Bool = false
    
    var requiredSourceTrackIDs: [NSValue]?
    
    var requiredSourceTrackIDsDic: [CMPersistentTrackID : VCVideoTrackDescription] = [:]
    
    var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    
    var videoProcessProtocol: VCVideoProcessProtocol?
    
    var trackBundle: VCTrackBundle = VCTrackBundle()
    
    var transitions: [VCTransition] = []
    
}
