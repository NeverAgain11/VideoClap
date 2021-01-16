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
    case timeRangeError
}

extension AVMutableAudioMixInputParameters {

    func setAudioProcessingTap(cookie: VCTapToken) throws {
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(cookie).toOpaque()),
            init: tapInit,
            finalize: tapFinalize,
            prepare: nil,
            unprepare: nil,
            process: tapProcess)
        
        var tap: Unmanaged<MTAudioProcessingTap>?
        
        let err = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
        if err == noErr {
            if let mtTap = tap?.takeRetainedValue() {
                self.audioTapProcessor = mtTap
            } else {
                throw VCAudioProcessingTapError.initError
            }
        } else {
            throw VCAudioProcessingTapError.initError
        }
        tokens.insert(cookie)
    }
}

private func tapFinalize(tap: MTAudioProcessingTap) {
    let token = Unmanaged<VCTapToken>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
    tokens.remove(token)
}

private func tapUnprepare(tap: MTAudioProcessingTap) {
    
}

private func tapPrepare(tap: MTAudioProcessingTap, maxFrames: CMItemCount, processingFormat: UnsafePointer<AudioStreamBasicDescription>) {
    
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
    let trackID = tapToken.trackID
    let processCallback = tapToken.processCallback
    if status == noErr && timeRange.isValid {
        processCallback.handle(audios: tapToken.audios,
                               trackID: trackID,
                               timeRange: timeRange,
                               inCount: numberFrames,
                               inFlag: flags,
                               outBuffer: bufferListInOut,
                               outCount: numberFramesOut,
                               outFlag: flagsOut,
                               error: nil)
    } else {
        processCallback.handle(audios: tapToken.audios,
                               trackID: trackID,
                               timeRange: timeRange,
                               inCount: numberFrames,
                               inFlag: flags,
                               outBuffer: bufferListInOut,
                               outCount: numberFramesOut,
                               outFlag: flagsOut,
                               error: VCAudioProcessingTapError.timeRangeError)
    }
    
}
