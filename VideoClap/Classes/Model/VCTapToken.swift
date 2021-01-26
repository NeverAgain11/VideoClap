//
//  VCTapToken.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/9.
//

import Foundation
import AVFoundation

/// 使用Token 强制持用  VCAudioProcessingTapProcessProtocol对象，防止在使用MTAudioProcessingTap时 MTAudioProcessingTapCallbacks  process回调中取不到 VCAudioProcessingTapProcessProtocol 对象导致内存访问错误
public class VCTapToken: NSObject {
    var processCallback: VCAudioProcessingTapProcessProtocol
    var audioTrack: VCAudioTrackDescription
    
    init(processCallback: VCAudioProcessingTapProcessProtocol, audioTrack: VCAudioTrackDescription) {
        self.processCallback = processCallback
        self.audioTrack = audioTrack
    }
}
