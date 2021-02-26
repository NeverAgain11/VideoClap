//
//  VCVideoInstruction.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

public class VCVideoInstruction: NSObject, AVVideoCompositionInstructionProtocol {
    
    public var timeRange: CMTimeRange = .zero
    
    public var enablePostProcessing: Bool = false
    
    public var containsTweening: Bool = false
    
    public var requiredSourceTrackIDs: [NSValue]?
    
    var requiredSourceTrackIDsDic: [CMPersistentTrackID : VCVideoTrackDescription] = [:]
    
    public var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    
    weak var videoProcessProtocol: VCVideoProcessProtocol?
    
    public var trackBundle: VCTrackBundle = VCTrackBundle()
    
    public var transitions: [VCTransition] = []
    
}
