//
//  VCAudioProcessingTapProcessProtocol.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/8.
//

import AVFoundation

public protocol VCAudioProcessingTapProcessProtocol: NSObject {
    
    var tapTokens: [VCTapToken] { get set }
    
    func handle(trackID: String,
                timeRange: CMTimeRange,
                inCount: CMItemCount,
                inFlag: MTAudioProcessingTapFlags,
                outBuffer: UnsafeMutablePointer<AudioBufferList>,
                outCount: UnsafeMutablePointer<CMItemCount>,
                outFlag: UnsafeMutablePointer<MTAudioProcessingTapFlags>,
                error: VCAudioProcessingTapError?)
}
