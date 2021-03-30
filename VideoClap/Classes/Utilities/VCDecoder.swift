//
//  VCDecoder.swift
//  VideoClap
//
//  Created by lai001 on 2021/3/24.
//

import Foundation
import VideoToolbox

public protocol VCDecoderDelegate: NSObject {
    func decodeFinish(status: OSStatus, infoFlags: VTDecodeInfoFlags, imageBuffer: CVImageBuffer?, presentationTimeStamp: CMTime, presentationDuration: CMTime)
}

public class VCDecoder: NSObject {
    
    public weak var delegate: VCDecoderDelegate?
    
    private var decompressionSession: VTDecompressionSession?
    
    private var decoderFormatDescription: CMVideoFormatDescription?
    
    public var codecType: CMVideoCodecType = kCMVideoCodecType_H264
    
    public lazy var decoderSpecification: [String:Any]? = {
        return nil
        var decoderSpecification: [String:Any] = [:]
//        encoderSpecification[kVTVideoEncoderSpecification_EncoderID as String]
        return decoderSpecification
    }()
    
    public lazy var imageBufferAttributes: [String:Any]? = {
        var imageBufferAttributes: [String:Any] = [:]
        imageBufferAttributes[kCVPixelBufferPixelFormatTypeKey as String] = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
//        imageBufferAttributes[kCVPixelBufferIOSurfacePropertiesKey as String] = [:]
        imageBufferAttributes[kCVPixelBufferOpenGLESCompatibilityKey as String] = kCFBooleanTrue
        return imageBufferAttributes
    }()
    
    public var decodeWidth: Int32 = 0 {
        didSet {
            imageBufferAttributes?[kCVPixelBufferWidthKey as String] = decodeWidth
        }
    }
    public var decodeHeight: Int32 = 0 {
        didSet {
            imageBufferAttributes?[kCVPixelBufferHeightKey as String] = decodeHeight
        }
    }
    public var pixelFormat: OSType = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange {
        didSet {
            imageBufferAttributes?[kCVPixelBufferPixelFormatTypeKey as String] = pixelFormat
        }
    }
    
    public var realTime: CFBoolean = kCFBooleanFalse
    
    public var extensions: CFDictionary?
    
    private var callback: VTDecompressionOutputCallbackRecord?
    
    public var threadCount: NSNumber = NSNumber(value: 1)
    
    public override init() {
        super.init()
    }
    
    func setup() throws {
        guard decompressionSession == nil else {
            throw NSError(domain: "VCDecoder", code: 1, userInfo: [NSLocalizedFailureReasonErrorKey : ""])
        }
        var status = CMVideoFormatDescriptionCreate(allocator: kCFAllocatorDefault,
                                                    codecType: codecType,
                                                    width: decodeWidth,
                                                    height: decodeHeight,
                                                    extensions: extensions,
                                                    formatDescriptionOut: &decoderFormatDescription)
        if status != noErr {
            throw NSError(domain: "VCDecoder", code: Int(status), userInfo: [NSLocalizedFailureReasonErrorKey : VCHelper.vtErrorCode(status)])
        }
        
        callback = VTDecompressionOutputCallbackRecord(decompressionOutputCallback: outputCallback,
                                                       decompressionOutputRefCon: Unmanaged.passUnretained(self).toOpaque())
        
        status = VTDecompressionSessionCreate(allocator: kCFAllocatorDefault,
                                              formatDescription: decoderFormatDescription.unsafelyUnwrapped,
                                              decoderSpecification: decoderSpecification as CFDictionary?,
                                              imageBufferAttributes: imageBufferAttributes as CFDictionary?,
                                              outputCallback: &callback!,
                                              decompressionSessionOut: &decompressionSession)
        
        if status != noErr {
            throw NSError(domain: "VCDecoder", code: Int(status), userInfo: [NSLocalizedFailureReasonErrorKey : VCHelper.vtErrorCode(status)])
        }
        
        status = VTSessionSetProperty(decompressionSession.unsafelyUnwrapped, key: kVTDecompressionPropertyKey_RealTime, value: realTime)
        if status != noErr {
            throw NSError(domain: "VCDecoder", code: Int(status), userInfo: [NSLocalizedFailureReasonErrorKey : VCHelper.vtErrorCode(status)])
        }
        
//        status = VTSessionSetProperty(decompressionSession.unsafelyUnwrapped, key: kVTDecompressionPropertyKey_ThreadCount, value: threadCount)
//        if status != noErr {
//            throw NSError(domain: "VCDecoder", code: Int(status), userInfo: [NSLocalizedFailureReasonErrorKey : VCHelper.vtErrorCode(status)])
//        }
    }
    
    public func stopDecoder() throws {
        guard let compressionSession = self.decompressionSession else { return }
        VTDecompressionSessionInvalidate(compressionSession)
        self.decompressionSession = nil
    }
    
    public func decode(sampleBuffer: CMSampleBuffer) throws {
        guard let _decompressionSession = decompressionSession else {
            throw NSError(domain: "VCDecoder", code: 2, userInfo: [NSLocalizedFailureReasonErrorKey : ""])
        }
        var outFlag: VTDecodeInfoFlags = VTDecodeInfoFlags(rawValue: 0)
        var status = VTDecompressionSessionDecodeFrame(_decompressionSession,
                                                       sampleBuffer: sampleBuffer,
                                                       flags: VTDecodeFrameFlags(rawValue: 0),
                                                       frameRefcon: nil,
                                                       infoFlagsOut: &outFlag)
        status = VTDecompressionSessionWaitForAsynchronousFrames(_decompressionSession)
        if status != noErr {
            throw NSError(domain: "VCDecoder", code: Int(status), userInfo: [NSLocalizedFailureReasonErrorKey : VCHelper.vtErrorCode(status)])
        }
    }
    
    private var outputCallback: VTDecompressionOutputCallback = { (decompressionOutputRefCon: UnsafeMutableRawPointer?, sourceFrameRefCon: UnsafeMutableRawPointer?, status: OSStatus, infoFlags: VTDecodeInfoFlags, imageBuffer: CVImageBuffer?, presentationTimeStamp: CMTime, presentationDuration: CMTime) in
        let decoder: VCDecoder = Unmanaged<VCDecoder>.fromOpaque(decompressionOutputRefCon.unsafelyUnwrapped).takeUnretainedValue()
        decoder.delegate?.decodeFinish(status: status,
                                       infoFlags: infoFlags,
                                       imageBuffer: imageBuffer,
                                       presentationTimeStamp: presentationTimeStamp,
                                       presentationDuration: presentationDuration)
    }
    
}
