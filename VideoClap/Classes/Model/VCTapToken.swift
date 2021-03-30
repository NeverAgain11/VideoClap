//
//  VCTapToken.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/9.
//

import Foundation
import AVFoundation

/// Force retain the vcaudioprocessingtapprocessprotocol object to avoid memory access error
public class VCTapToken: NSObject {
    var processCallback: VCAudioProcessingTapProcessProtocol
    var audioTrack: VCAudioTrackDescription
    
    init(processCallback: VCAudioProcessingTapProcessProtocol, audioTrack: VCAudioTrackDescription) {
        self.processCallback = processCallback
        self.audioTrack = audioTrack
    }
}
