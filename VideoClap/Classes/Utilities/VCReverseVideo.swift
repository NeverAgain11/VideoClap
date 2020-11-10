//
//  VCReverseVideo.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/30.
//

import Foundation
import AVFoundation

public enum VCReverseVideoError: Error {
    case inputFileNotExist
    case targetIsNil
    case inputFileNotPlayable
    case mediaTrackNotFound
    case addReaderVideoOutputFailed
    case addReaderAudioOutputFailed
    case startReadingFailed
    case startWritingFailed
    case internalError
}

public class VCReverseVideo: NSObject {
    
    public var exportUrl: URL?
    public var inputUrl: URL?
    
    private var assetReader: AVAssetReader?
    private var assetWriter: AVAssetWriter?
    
    private var assetReaderVideoOutput: AVAssetReaderTrackOutput?
    private var assetWriterVideoInput: AVAssetWriterInput?
    private var assetWriterVideoInputAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    private var assetReaderAudioOutput: AVAssetReaderTrackOutput?
    private var assetWriterAudioInput: AVAssetWriterInput?
    private var assetWriterAudioInputAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    private var inputVideoTrack: AVAssetTrack?
    private var inputAudioTrack: AVAssetTrack?
    
    func getVideoReaderOutputSettings() -> [String:Any]? {
        guard let _ = inputVideoTrack else { return nil }
        var settings: [String : Any] = [:]
        settings[String(kCVPixelBufferPixelFormatTypeKey)] = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
//        settings[String(kCVPixelBufferOpenGLESCompatibilityKey)] = true
        return settings
    }
    
    func getAudioReaderOutputSettings() -> [String:Any]? {
        guard let _ = inputAudioTrack else { return nil }
        var settings: [String : Any] = [:]
        settings[AVFormatIDKey] = kAudioFormatLinearPCM
        return settings
    }
    
    func getVideoWriterInputSettings() -> [String:Any]? {
        guard let inputVideoTrack = inputVideoTrack else { return nil }
        var settings: [String : Any] = [:]
        settings[AVVideoCodecKey] = AVVideoCodecH264
        settings[AVVideoWidthKey] = inputVideoTrack.naturalSize.width
        settings[AVVideoHeightKey] = inputVideoTrack.naturalSize.height
        return settings
    }
    
    func getAudioWriterInputSettings() -> [String:Any]? {
        var settings: [String : Any] = [:]
        
//        if let inputAudioTrack = inputAudioTrack,
//           let formatDescriptions = inputAudioTrack.formatDescriptions as? [CMFormatDescription],
//           let formatDescription = formatDescriptions.first {
//            settings[AVFormatIDKey] = kAudioFormatMPEG4AAC
//            settings[AVEncoderBitRateKey] = 128000
//            settings[AVSampleRateKey] = 44100
//            settings[AVChannelLayoutKey] = formatDescription.audioChannelLayout
//            settings[AVNumberOfChannelsKey] = 2
//        } else {
//
//        }
        
        settings[AVFormatIDKey] = kAudioFormatMPEG4AAC
        settings[AVEncoderBitRateKey] = 128000
        settings[AVSampleRateKey] = 44100
        settings[AVNumberOfChannelsKey] = 2
        
        var stereoChannelLayout = AudioChannelLayout()
        stereoChannelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo
        stereoChannelLayout.mChannelBitmap = AudioChannelBitmap(rawValue: 0)
        stereoChannelLayout.mNumberChannelDescriptions = 0
        
        if let dataCount = MemoryLayout.offset(of: \AudioChannelLayout.mChannelDescriptions) {
            let channelLayoutAsData = Data(bytes: &stereoChannelLayout, count: dataCount)
            settings[AVChannelLayoutKey] = channelLayoutAsData
        }
        
        return settings
    }
    
    public func prepare() throws {
        guard let inputUrl = self.inputUrl else { throw VCReverseVideoError.inputFileNotExist }
        guard let exportUrl = self.exportUrl else { throw VCReverseVideoError.targetIsNil }
        
        if FileManager.default.fileExists(atPath: exportUrl.path) {
            try FileManager.default.removeItem(at: exportUrl)
        }
        
        let asset = AVAsset(url: inputUrl)
        if asset.isPlayable == false {
            throw VCReverseVideoError.inputFileNotPlayable
        }
        inputVideoTrack = asset.tracks(withMediaType: .video).first
        inputAudioTrack = asset.tracks(withMediaType: .audio).first
        
        if inputVideoTrack == nil && inputAudioTrack == nil {
            throw VCReverseVideoError.mediaTrackNotFound
        }
        
        assetReader = try AVAssetReader(asset: asset)
        assetWriter = try AVAssetWriter(outputURL: exportUrl, fileType: .mov)
        
        if let inputVideoTrack = self.inputVideoTrack {
            assetReaderVideoOutput = AVAssetReaderTrackOutput(track: inputVideoTrack, outputSettings: getVideoReaderOutputSettings())
        }
        
        if let inputAudioTrack = self.inputAudioTrack {
            assetReaderAudioOutput = AVAssetReaderTrackOutput(track: inputAudioTrack, outputSettings: getAudioReaderOutputSettings())
        }
        
        if let assetReader = assetReader, let assetReaderVideoOutput = assetReaderVideoOutput {
            if assetReader.canAdd(assetReaderVideoOutput) == false {
                throw VCReverseVideoError.addReaderVideoOutputFailed
            }
            assetReader.add(assetReaderVideoOutput)
        }
        
        if let assetReader = assetReader, let assetReaderAudioOutput = assetReaderAudioOutput {
            if assetReader.canAdd(assetReaderAudioOutput) == false {
                throw VCReverseVideoError.addReaderAudioOutputFailed
            }
            assetReader.add(assetReaderAudioOutput)
        }
        
        if let settings = getAudioWriterInputSettings() {
            let input = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
            input.expectsMediaDataInRealTime = false
            assetWriterAudioInput = input
            
            if assetWriter?.canAdd(input) == true {
                assetWriter?.add(input)
            } else {
                throw VCReverseVideoError.internalError
            }
        }
        
        if let settings = getVideoWriterInputSettings() {
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
            input.expectsMediaDataInRealTime = false
            assetWriterVideoInput = input
            assetWriter?.add(input)
            if assetWriter?.canAdd(input) == true {
                assetWriter?.add(input)
            } else {
                throw VCReverseVideoError.internalError
            }
            assetWriterVideoInputAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        }
    }
    
    public func start() throws {
        let queue = DispatchQueue(label: "reverse queue")
        
        queue.async {
            self.asyncStart()
        }
    }
    
    func asyncStart() {

        if assetReader?.startReading() == false {
            return
        }
        
        if assetWriter?.startWriting() == false {
            return
        }
        
        assetWriter?.startSession(atSourceTime: .zero)
        
        if let assetWriterVideoInput = self.assetWriterVideoInput {
            
            var samples: [CMSampleBuffer] = []
            
            while let sampleBuffer = self.assetReaderVideoOutput?.copyNextSampleBuffer() {
                samples.append(sampleBuffer)
            }
            
            for sampleBuffer in samples.reversed() {
                
                while true {
                    
                    if self.assetWriterVideoInputAdaptor?.assetWriterInput.isReadyForMoreMediaData == true {
//                        assetWriterVideoInput.append(sampleBuffer)
                        
                        self.assetWriterVideoInputAdaptor?.append(CMSampleBufferGetImageBuffer(sampleBuffer)!, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                        break
                    } else {
                        Thread.sleep(forTimeInterval: 0.1)
                    }
                    
                }
                
                log.debug(CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds)
                
            }
            
        }
        
    }
    
    func cancel() {
        assetReader?.cancelReading()
        assetWriter?.cancelWriting()
        
        assetWriterAudioInput?.markAsFinished()
        assetWriterVideoInput?.markAsFinished()
        
        assetWriter?.finishWriting {
            
        }
    }
    
}
