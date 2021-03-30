//
//  VCEncoder.swift
//  VideoClap
//
//  Created by lai001 on 2021/3/24.
//

import Foundation
import VideoToolbox

public protocol VCEncoderDelegate: NSObject {
    func encodeFinish(status: OSStatus, infoFlags: VTEncodeInfoFlags, sampleBuffer: CMSampleBuffer?)
}

public class VCEncoder: NSObject {
    
    public weak var delegate: VCEncoderDelegate?
    
    public var profile: CFString = kVTProfileLevel_H264_Baseline_AutoLevel
    public var encodeWidth: Int32 = 0 {
        didSet {
            imageBufferAttributes?[kCVPixelBufferWidthKey as String] = encodeWidth
        }
    }
    public var encodeHeight: Int32 = 0 {
        didSet {
            imageBufferAttributes?[kCVPixelBufferHeightKey as String] = encodeHeight
        }
    }
    public var pixelFormat: OSType = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange {
        didSet {
            imageBufferAttributes?[kCVPixelBufferPixelFormatTypeKey as String] = pixelFormat
        }
    }
    public var encodeType: CMVideoCodecType = kCMVideoCodecType_H264
    public var bitRate: CFIndex = 1024 * 1024 * 24
    public var frameRate: CFIndex = 24
    public var maxKeyFrameInterval: CFIndex = 1
    public var allowFrameReordering: CFBoolean = kCFBooleanFalse
    public var realTime: CFBoolean = kCFBooleanFalse
    
    public lazy var imageBufferAttributes: [String:Any]? = {
        var imageBufferAttributes: [String:Any] = [:]
        imageBufferAttributes[kCVPixelBufferPixelFormatTypeKey as String] = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        imageBufferAttributes[kCVPixelBufferIOSurfacePropertiesKey as String] = [:]
        imageBufferAttributes[kCVPixelBufferOpenGLESCompatibilityKey as String] = kCFBooleanTrue
        return imageBufferAttributes
    }()
    
    public lazy var encoderSpecification: [String:Any]? = {
        return nil
        var encoderSpecification: [String:Any] = [:]
//        encoderSpecification[kVTVideoEncoderSpecification_EncoderID as String]
        return encoderSpecification
    }()
    
    private var compressionSession: VTCompressionSession?
    
    public override init() {
        super.init()
    }
    
    public func setup() throws {
        guard compressionSession == nil else {
            throw NSError(domain: "VCEncoder", code: 2, userInfo: [NSLocalizedFailureReasonErrorKey : ""])
        }
        var status = VTCompressionSessionCreate(allocator: kCFAllocatorDefault,
                                                width: encodeWidth,
                                                height: encodeHeight,
                                                codecType: encodeType,
                                                encoderSpecification: encoderSpecification as CFDictionary?,
                                                imageBufferAttributes: imageBufferAttributes as CFDictionary?,
                                                compressedDataAllocator: kCFAllocatorDefault,
                                                outputCallback: compressionOutputCallback,
                                                refcon: Unmanaged.passUnretained(self).toOpaque(),
                                                compressionSessionOut: &compressionSession)
        if status != noErr {
            throw NSError(domain: "VCEncoder", code: Int(status), userInfo: [NSLocalizedFailureReasonErrorKey : VCHelper.vtErrorCode(status)])
        }
        
        status = VTSessionSetProperty(compressionSession.unsafelyUnwrapped, key: kVTCompressionPropertyKey_ProfileLevel, value: profile)
        if status != noErr {
            throw NSError(domain: "VCEncoder", code: Int(status), userInfo: [NSLocalizedFailureReasonErrorKey : VCHelper.vtErrorCode(status)])
        }
        
        status = VTSessionSetProperty(compressionSession.unsafelyUnwrapped, key: kVTCompressionPropertyKey_RealTime, value: realTime)
        if status != noErr {
            throw NSError(domain: "VCEncoder", code: Int(status), userInfo: [NSLocalizedFailureReasonErrorKey : VCHelper.vtErrorCode(status)])
        }
        
        status = VTSessionSetProperty(compressionSession.unsafelyUnwrapped, key: kVTCompressionPropertyKey_AllowFrameReordering, value: allowFrameReordering)
        if status != noErr {
            throw NSError(domain: "VCEncoder", code: Int(status), userInfo: [NSLocalizedFailureReasonErrorKey : VCHelper.vtErrorCode(status)])
        }
        
        status = VTSessionSetProperty(compressionSession.unsafelyUnwrapped, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: (frameRate * maxKeyFrameInterval) as AnyObject)
        if status != noErr {
            throw NSError(domain: "VCEncoder", code: Int(status), userInfo: [NSLocalizedFailureReasonErrorKey : VCHelper.vtErrorCode(status)])
        }
        
        status = VTSessionSetProperty(compressionSession.unsafelyUnwrapped, key: kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, value: maxKeyFrameInterval as AnyObject)
        if status != noErr {
            throw NSError(domain: "VCEncoder", code: Int(status), userInfo: [NSLocalizedFailureReasonErrorKey : VCHelper.vtErrorCode(status)])
        }
        
        status = VTSessionSetProperty(compressionSession.unsafelyUnwrapped, key: kVTCompressionPropertyKey_AverageBitRate, value: bitRate as AnyObject)
        if status != noErr {
            throw NSError(domain: "VCEncoder", code: Int(status), userInfo: [NSLocalizedFailureReasonErrorKey : VCHelper.vtErrorCode(status)])
        }
        
        var dataLimitBytesPerSecondValue: Int64 = Int64(Float(bitRate) * 1.5 / 8)
        let bytesPerSecond: CFNumber = CFNumberCreate(kCFAllocatorDefault, CFNumberType.sInt64Type, &dataLimitBytesPerSecondValue);
        var oneSecondValue: Int64 = 1
        let oneSecond: CFNumber = CFNumberCreate(kCFAllocatorDefault, CFNumberType.sInt64Type, &oneSecondValue);
        let rateLimitValues = CFArrayCreateMutable(kCFAllocatorDefault, 0, nil)
        CFArrayAppendValue(rateLimitValues, Unmanaged.passRetained(bytesPerSecond).autorelease().toOpaque())
        CFArrayAppendValue(rateLimitValues, Unmanaged.passRetained(oneSecond).autorelease().toOpaque())
        status = VTSessionSetProperty(compressionSession.unsafelyUnwrapped, key: kVTCompressionPropertyKey_DataRateLimits, value: rateLimitValues as CFTypeRef)
        if (status != noErr) {
            throw NSError(domain: "VCEncoder", code: Int(status), userInfo: [NSLocalizedFailureReasonErrorKey : VCHelper.vtErrorCode(status)])
        }
        
        status = VTCompressionSessionPrepareToEncodeFrames(compressionSession.unsafelyUnwrapped)
        if status != noErr {
            throw NSError(domain: "VCEncoder", code: Int(status), userInfo: [NSLocalizedFailureReasonErrorKey : ""])
        }
    }
    
    public func stopEncoder() throws {
        guard let compressionSession = self.compressionSession else { return }
        let status = VTCompressionSessionCompleteFrames(compressionSession, untilPresentationTimeStamp: CMTime.invalid)
        VTCompressionSessionInvalidate(compressionSession)
        if status == noErr {
            self.compressionSession = nil
        } else {
            throw NSError(domain: "VCEncoder", code: Int(status), userInfo: [NSLocalizedFailureReasonErrorKey : VCHelper.vtErrorCode(status)])
        }
    }
    
    public func encode(buffer: CVPixelBuffer, keyFrame: CFBoolean?, pts: CMTime, duration: CMTime) throws {
        guard let compressionSession = self.compressionSession else {
            throw NSError(domain: "VCEncoder", code: 1, userInfo: [NSLocalizedFailureReasonErrorKey : ""])
        }
        var frameProperties: [String:Any]?
        if let _keyFrame = keyFrame {
            frameProperties = [:]
            frameProperties?[kVTEncodeFrameOptionKey_ForceKeyFrame as String] = _keyFrame
        }
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        var status = VTCompressionSessionEncodeFrame(compressionSession,
                                                     imageBuffer: buffer,
                                                     presentationTimeStamp: pts,
                                                     duration: duration,
                                                     frameProperties: frameProperties as CFDictionary?,
                                                     sourceFrameRefcon: nil,
                                                     infoFlagsOut: nil)
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        if status == noErr {
            
        } else {
            throw NSError(domain: "VCEncoder", code: Int(status), userInfo: [NSLocalizedFailureReasonErrorKey : VCHelper.vtErrorCode(status)])
        }
    }
    
    // MARK: - Compression callback
    private var compressionOutputCallback: VTCompressionOutputCallback = { (outputCallbackRefCon: UnsafeMutableRawPointer?, sourceFrameRefCon: UnsafeMutableRawPointer?, status: OSStatus, infoFlags: VTEncodeInfoFlags, sampleBuffer: CMSampleBuffer?) in
        let encoder: VCEncoder = Unmanaged<VCEncoder>.fromOpaque(outputCallbackRefCon.unsafelyUnwrapped).takeUnretainedValue()
        encoder.delegate?.encodeFinish(status: status,
                                       infoFlags: infoFlags,
                                       sampleBuffer: sampleBuffer)
    }
    
}
