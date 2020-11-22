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
    
    var imageTracks: [VCImageTrackDescription] = []
    
    var videoTracks: [VCVideoTrackDescription] = []
    
    var audioTracks: [VCAudioTrackDescription] = []
    
    var lottieTracks: [VCLottieTrackDescription] = []
    
    var laminationTracks: [VCLaminationTrackDescription] = []
    
    var transitions: [VCTransition] = []
    
    var trajectories: [VCTrajectoryProtocol] = []
    
}
