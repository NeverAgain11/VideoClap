//
//  VCAudioProcessingTap.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/22.
//

import AVFoundation

public enum VCAudioProcessingTapError: Error {
    case initError
    case timeRangeError
}

internal class VCAudioProcessingTap: NSObject, NSCopying, NSMutableCopying {
    
    private(set) var mtTap: MTAudioProcessingTap!
    
    private(set) var processCallback: VCAudioProcessingTapProcessProtocol
    
    private(set) var trackID: String
    
    init?(trackID: String, processCallback: VCAudioProcessingTapProcessProtocol) throws {
        self.trackID = trackID
        self.processCallback = processCallback
        super.init()
        
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            init: tapInit,
            finalize: nil,
            prepare: nil,
            unprepare: nil,
            process: tapProcess)
        
        var tap: Unmanaged<MTAudioProcessingTap>?
        
        let err = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
        if err == noErr {
            if let mtTap = tap?.takeRetainedValue() {
                self.mtTap = mtTap
            } else {
                throw VCAudioProcessingTapError.initError
            }
        } else {
            throw VCAudioProcessingTapError.initError
        }
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    func mutableCopy(with zone: NSZone? = nil) -> Any {
        let holder = type(of: self).init()
        return holder
    }
    
}

private func tapFinalize(tap: MTAudioProcessingTap) {
    
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
    let processingTapStorage = Unmanaged<VCAudioProcessingTap>.fromOpaque(MTAudioProcessingTapGetStorage(tap)) // FIXME: EXC_BAD_ACCESS ERROR - ClientProcessingTapManager (28): EXC_BAD_ACCESS (code=, address=)
    let processingTap = processingTapStorage.takeUnretainedValue()
    
    var timeRange: CMTimeRange = CMTimeRange.zero
    let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, &timeRange, numberFramesOut)
    if status == noErr && timeRange.isValid {
        processingTap.processCallback.handle(trackID: processingTap.trackID,
                                             timeRange: timeRange,
                                             inCount: numberFrames,
                                             inFlag: flags,
                                             outBuffer: bufferListInOut,
                                             outCount: numberFramesOut,
                                             outFlag: flagsOut,
                                             error: nil)
    } else {
        processingTap.processCallback.handle(trackID: processingTap.trackID,
                                             timeRange: timeRange,
                                             inCount: numberFrames,
                                             inFlag: flags,
                                             outBuffer: bufferListInOut,
                                             outCount: numberFramesOut,
                                             outFlag: flagsOut,
                                             error: VCAudioProcessingTapError.timeRangeError)
    }
}
