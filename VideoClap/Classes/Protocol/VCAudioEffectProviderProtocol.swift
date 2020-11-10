//
//  VCAudioEffectProviderProtocol.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/9.
//

import AVFoundation

public protocol VCAudioEffectProviderProtocol: NSObject {
    
    func handle(timeRange: CMTimeRange,
                inCount: CMItemCount,
                inFlag: MTAudioProcessingTapFlags,
                outBuffer: UnsafeMutablePointer<AudioBufferList>,
                outCount: UnsafeMutablePointer<CMItemCount>,
                outFlag: UnsafeMutablePointer<MTAudioProcessingTapFlags>,
                pcmFormat: AVAudioFormat)
    
}
