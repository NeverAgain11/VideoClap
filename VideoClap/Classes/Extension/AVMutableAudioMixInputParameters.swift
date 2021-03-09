//
//  AVMutableAudioMixInputParameters.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/8.
//

import AVFoundation

private var tokens: Set<VCTapToken> = {
    return []
}()

public enum VCAudioProcessingTapError: Error {
    case initError
    case getSourceAudioError(OSStatus)
}

extension AVMutableAudioMixInputParameters {

    func setAudioProcessingTap(token: VCTapToken) throws {
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(token).toOpaque()),
            init: tapInit,
            finalize: tapFinalize,
            prepare: tapPrepare,
            unprepare: nil,
            process: tapProcess)
        
        var tap: Unmanaged<MTAudioProcessingTap>?
        
        let err = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
        if err == noErr, let mtTap = tap?.takeRetainedValue() {
            self.audioTapProcessor = mtTap
        } else {
            throw VCAudioProcessingTapError.initError
        }
        tokens.insert(token)
    }
}

private func tapFinalize(tap: MTAudioProcessingTap) {
    let token = Unmanaged<VCTapToken>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
    tokens.remove(token)
}

private func tapUnprepare(tap: MTAudioProcessingTap) {
    
}

private func tapPrepare(tap: MTAudioProcessingTap, maxFrames: CMItemCount, processingFormat: UnsafePointer<AudioStreamBasicDescription>) {
    let tapTokenStorage = Unmanaged<VCTapToken>.fromOpaque(MTAudioProcessingTapGetStorage(tap))
    let tapToken = tapTokenStorage.takeUnretainedValue()
    tapToken.audioTrack.processingFormat = AVAudioFormat(streamDescription: processingFormat)
    tapToken.audioTrack.maxFrames = maxFrames
}

private func tapInit(tap: MTAudioProcessingTap, clientInfo: UnsafeMutableRawPointer?, tapStorageOut: UnsafeMutablePointer<UnsafeMutableRawPointer?>) {
    tapStorageOut.pointee = clientInfo
}

private func tapProcess(tap: MTAudioProcessingTap,
                        numberFrames: CMItemCount,
                        flags: MTAudioProcessingTapFlags,
                        bufferListInOut: UnsafeMutablePointer<AudioBufferList>,
                        numberFramesOut: UnsafeMutablePointer<CMItemCount>,
                        flagsOut: UnsafeMutablePointer<MTAudioProcessingTapFlags>) {
    let tapTokenStorage = Unmanaged<VCTapToken>.fromOpaque(MTAudioProcessingTapGetStorage(tap))
    let tapToken = tapTokenStorage.takeUnretainedValue()
     
    var timeRange: CMTimeRange = CMTimeRange.zero
    let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, &timeRange, numberFramesOut)
    let processCallback = tapToken.processCallback
    if status == noErr {
        processCallback.handle(audioTrack: tapToken.audioTrack,
                               timeRange: timeRange,
                               inCount: numberFrames,
                               inFlag: flags,
                               outBuffer: bufferListInOut,
                               outCount: numberFramesOut,
                               outFlag: flagsOut,
                               error: nil)
    } else {
        processCallback.handle(audioTrack: tapToken.audioTrack,
                               timeRange: timeRange,
                               inCount: numberFrames,
                               inFlag: flags,
                               outBuffer: bufferListInOut,
                               outCount: numberFramesOut,
                               outFlag: flagsOut,
                               error: VCAudioProcessingTapError.getSourceAudioError(status))
    }
    
}
