//
//  VCAudioNode.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/23.
//

import AVFoundation

public class VCAudioNode: NSObject {
    
    public private(set) var socket: AUNode = AUNode()
    
    internal var audioComponentDescription: AudioComponentDescription
    
    public private(set) var unit: AudioUnit?
    
    public private(set) weak var engine: VCAudioEngine?
    
    private override init() {
        audioComponentDescription = AudioComponentDescription()
        super.init()
    }
    
    public init(componentType: UInt32, componentSubType: UInt32) {
        audioComponentDescription = AudioComponentDescription(componentType: componentType, componentSubType: componentSubType)
        super.init()
    }
    
    public func parameters() -> [VCAudioUnitParameter] {
        guard let unit = self.unit else { return [] }
        var out = [VCAudioUnitParameter]()
        
        var parameterListSize: UInt32 = 0
        let parameterSize = MemoryLayout<AudioUnitParameterID>.size
        AudioUnitGetPropertyInfo(unit, kAudioUnitProperty_ParameterList,
                                 kAudioUnitScope_Global,
                                 0, &parameterListSize, nil);
        
        let numberOfParameters = Int(parameterListSize) / parameterSize

        let parameterIds = UnsafeMutablePointer<UInt32>.allocate(capacity: Int(parameterListSize))
        AudioUnitGetProperty(unit, kAudioUnitProperty_ParameterList,
                             kAudioUnitScope_Global,
                             0, parameterIds, &parameterListSize);

        var info = AudioUnitParameterInfo()
        var infoSize = UInt32(MemoryLayout<AudioUnitParameterInfo>.size)
        
        for i in 0 ..< numberOfParameters {
            let id = parameterIds[i]
            AudioUnitGetProperty(unit, kAudioUnitProperty_ParameterInfo,
                                 kAudioUnitScope_Global,
                                 id, &info, &infoSize);
            out += [VCAudioUnitParameter(info, id: id)]
        }
        return out
    }
    
    internal func addTo(engine: VCAudioEngine, socket: AUNode, unit: AudioUnit) {
        self.engine = engine
        self.socket = socket
        self.unit = unit
    }
    
    @discardableResult public func setRenderQuality(_ quality: UInt32) -> OSStatus {
        var _quality = quality
        let dataSize = UInt32(MemoryLayout<UInt32>.size)
        return self.setProperty(inID: kAudioUnitProperty_RenderQuality, inData: &_quality, inDataSize: dataSize)
    }
    
    @discardableResult public func setOfflineRender(_ flag: UInt32) -> OSStatus {
        var _flag = flag
        let dataSize = UInt32(MemoryLayout<UInt32>.size)
        return self.setProperty(inID: kAudioUnitProperty_OfflineRender, inData: &_flag, inDataSize: dataSize)
    }
    
    @discardableResult public func setMaximumFramesPerSlice(_ frames: AVAudioFrameCount) -> OSStatus {
        var maxFramesPerSlice: AVAudioFrameCount = frames
        let dataSize = UInt32(MemoryLayout<AVAudioFrameCount>.size)
        return self.setProperty(inID: kAudioUnitProperty_MaximumFramesPerSlice, inData: &maxFramesPerSlice, inDataSize: dataSize)
    }
    
    @discardableResult public func setProperty(inID: AudioUnitPropertyID,
                     inScope: AudioUnitScope = kAudioUnitScope_Global,
                     inElement: AudioUnitElement = 0,
                     inData: UnsafeRawPointer? = nil,
                     inDataSize: UInt32 = 0) -> OSStatus {
        
        guard let unit = self.unit else { return -1 }
        
        return AudioUnitSetProperty(unit,
                                    inID,
                                    inScope,
                                    inElement,
                                    inData,
                                    inDataSize)
    }
    
    @discardableResult public func getProperty(inID: AudioUnitPropertyID,
                     inScope: AudioUnitScope,
                     inElement: AudioUnitElement,
                     outData: UnsafeMutableRawPointer,
                     ioDataSize: UnsafeMutablePointer<UInt32>) -> OSStatus {
        guard let unit = self.unit else { return -1 }
        return AudioUnitGetProperty(unit,
                                    inID,
                                    inScope,
                                    inElement,
                                    outData,
                                    ioDataSize)
    }
    
    @discardableResult public func setParameter(inID: AudioUnitParameterID,
                      inScope: AudioUnitScope = kAudioUnitScope_Global,
                      inElement: AudioUnitElement = 0,
                      inValue: AudioUnitParameterValue,
                      inBufferOffsetInFrames: UInt32 = 0) -> OSStatus {
        guard let unit = self.unit else { return -1 }
        return AudioUnitSetParameter(unit,
                                     inID,
                                     inScope,
                                     inElement,
                                     inValue,
                                     inBufferOffsetInFrames)
    }
    
    @discardableResult public func start() -> OSStatus {
        guard let unit = self.unit else { return -1 }
        return AudioOutputUnitStart(unit)
    }
    
    @discardableResult public func scheduledAudioSlice(timeStamp: AudioTimeStamp = AudioTimeStamp(),
                                                       buffer: UnsafeMutablePointer<AudioBufferList>,
                                                       numberFrames: UInt32,
                                                       completionProc: ScheduledAudioSliceCompletionProc? = nil,
                                                       completionProcUserData: UnsafeMutableRawPointer) -> OSStatus {
        var status = OSStatus()
        var slice = ScheduledAudioSlice(mTimeStamp: timeStamp,
                                        mCompletionProc: completionProc,
                                        mCompletionProcUserData: completionProcUserData,
                                        mFlags: AUScheduledAudioSliceFlags.scheduledAudioSliceFlag_BeganToRender,
                                        mReserved: 0,
                                        mReserved2: nil,
                                        mNumberFrames: numberFrames,
                                        mBufferList: buffer)
        status = setProperty(inID: kAudioUnitProperty_ScheduleAudioSlice,
                           inData: &slice,
                           inDataSize: UInt32(MemoryLayout<ScheduledAudioSlice>.size))
        return status
    }
    
    @discardableResult public func scheduleStartTimeStamp(timeStamp: AudioTimeStamp = AudioTimeStamp()) -> OSStatus {
        var startTimeStamp = timeStamp
        var status = OSStatus()
        status = setProperty(inID: kAudioUnitProperty_ScheduleStartTimeStamp,
                             inData: &startTimeStamp,
                             inDataSize: UInt32(MemoryLayout<AudioTimeStamp>.size))
        return status
    }
    
    @discardableResult public func render(flags: AudioUnitRenderActionFlags = AudioUnitRenderActionFlags(rawValue: 0),
                inTimeStamp: AudioTimeStamp = AudioTimeStamp(),
                numberFrames: UInt32,
                outBuffer: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        guard let unit = self.unit else { return -1 }
        var _flags = flags
        var _inTimeStamp = inTimeStamp
        return AudioUnitRender(unit, &_flags, &_inTimeStamp, 0, numberFrames, outBuffer)
    }
    
}
