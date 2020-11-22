//
//  VCRequestItem.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

public struct VCRequestItem {
    var sourceFrameDic: [String : CIImage] = [:]
    
    var imageTracks: [VCImageTrackDescription] = []
    
    var videoTracks: [VCVideoTrackDescription] = []
    
    var audioTracks: [VCAudioTrackDescription] = []
    
    var lottieTracks: [VCLottieTrackDescription] = []
    
    var laminationTracks: [VCLaminationTrackDescription] = []
    
    var transitions: [VCTransition] = []
    
    var trajectories: [VCTrajectoryProtocol] = []
}
