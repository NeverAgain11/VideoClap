//
//  VCVideoWriter.swift
//  VideoClap
//
//  Created by lai001 on 10/24/2020.
//

import AVFoundation
import UIKit
import Photos

public struct RenderSettings {
    
    var width: CGFloat = 720
    var height: CGFloat = 720
    var avCodecKey: String = AVVideoCodecH264
    var duration: CMTime = CMTime(seconds: 30.0, preferredTimescale: 2)
    
    var size: CGSize {
        set {
            self.width = newValue.width
            self.height = newValue.height
        }
        get {
            return CGSize(width: width, height: height)
        }
    }
    
    var outputURL: URL
    
    var avOutputSettings: [String : Any] {
        let avOutputSettings: [String : Any] = [
            AVVideoCodecKey: avCodecKey,
            AVVideoWidthKey: NSNumber(value: Float(width)),
            AVVideoHeightKey: NSNumber(value: Float(height)),
            AVVideoCompressionPropertiesKey: [AVVideoMaxKeyFrameIntervalKey: NSNumber(value: 1),
                                              AVVideoAverageBitRateKey: NSNumber(value: Int(width * height)),
                                              //                                              AVVideoProfileLevelKey: AVVideoProfileLevelH264High41,
                                              AVVideoExpectedSourceFrameRateKey: NSNumber(value: duration.timescale),]
        ]
        return avOutputSettings
    }
    
    var sourcePixelBufferAttributesDictionary: [String : Any] {
        let sourcePixelBufferAttributesDictionary = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: NSNumber(value: Float(width)),
            kCVPixelBufferHeightKey as String: NSNumber(value: Float(height)),
            kCVPixelBufferBytesPerRowAlignmentKey as String: NSNumber(value: 4 * Int(width)),
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: kCFBooleanTrue,
            kCVPixelBufferCGImageCompatibilityKey as String: kCFBooleanTrue
        ]
        return sourcePixelBufferAttributesDictionary as [String : Any]
    }
    
    public init(outputURL: URL,
         width: CGFloat = 720,
         height: CGFloat = 720,
         duration: CMTime = CMTime(seconds: 30.0, preferredTimescale: 2)) {
        self.outputURL = outputURL
        self.width = width
        self.height = height
        self.duration = duration
    }
    
}

public class VCVideoCreator: NSObject {
    
    // Apple suggests a timescale of 600 because it's a multiple of standard video rates 24, 25, 30, 60 fps etc.
    
    let settings: RenderSettings
    let videoWriter: VCVideoWriter
    
    lazy var images: [UIImage] = {
        let renderer = VCGraphicsRenderer()
        renderer.rendererRect.size = CGSize(width: settings.width, height: settings.height)
        let image = renderer.image { (cgcontext) in
            UIColor.black.setFill()
            UIRectFill(renderer.rendererRect)
        }
        return (0..<settings.duration.value).map({ _ in image }).compactMap({ $0 })
    }()
    
    public init(renderSettings: RenderSettings) {
        settings = renderSettings
        videoWriter = VCVideoWriter(renderSettings: settings)
        super.init()
    }
    
    func saveToLibrary(videoURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { (success, error) in
                if let error = error?.localizedDescription {
                    print(error)
                }
            }
        }
    }
    
    func removeFileAtURL(fileURL: URL) {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch let error {
            log.error(error)
        }
    }
    
    public func render(completion: @escaping () -> Void) {
        removeFileAtURL(fileURL: settings.outputURL)
        videoWriter.render(appendPixelBuffers: { (compositionTime: CMTime, feedImage: VCVideoWriter.FeedImage) -> Bool in
            let index = Int(compositionTime.value)
            if index < self.images.count - 1 {
                feedImage(self.images[index])
                return false
            } else {
                return true
            }
        }) {
            completion()
        }
    }
    
}

public class VCVideoWriter {
    
    typealias FeedImage = (_ image: UIImage) -> Void
    typealias Handler = (_ compositionTime: CMTime, FeedImage) -> Bool
    typealias Block = () -> Void
    
    var renderSettings: RenderSettings
    
    var assetWriter: AVAssetWriter!
    var videoWriterInput: AVAssetWriterInput!
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    
    private var finishBlock: Block?
    
    var isReadyForData: Bool {
        return videoWriterInput?.isReadyForMoreMediaData ?? false
    }
    
    init(renderSettings: RenderSettings) {
        self.renderSettings = renderSettings
    }
    
    func newPixelBuffer() -> CVPixelBuffer? {
        guard let pool = pixelBufferAdaptor.pixelBufferPool else {
            return nil
        }
        var pixelBufferOut: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBufferOut)
        if status == kCVReturnSuccess {
            return pixelBufferOut
        } else {
            return nil
        }
    }
    
    func pixelBufferFromImage(image: UIImage) -> CVPixelBuffer? {
        guard let pixelBuffer: CVPixelBuffer = newPixelBuffer() else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        }
        
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                      width: Int(renderSettings.width),
                                      height: Int(renderSettings.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        else {
            return nil
        }
        
        context.clear(CGRect(x: 0, y: 0, width: renderSettings.width, height: renderSettings.height))
        guard let willDrawImage = image.cgImage else {
            return nil
        }
        context.draw(willDrawImage, in: CGRect(x: 0, y: 0, width: renderSettings.width, height: renderSettings.height))
        return pixelBuffer
    }
    
    private func start() throws {
        videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: renderSettings.avOutputSettings)
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput,
                                                                  sourcePixelBufferAttributes: renderSettings.sourcePixelBufferAttributesDictionary)
        
        let videoWriter = try AVAssetWriter(outputURL: renderSettings.outputURL, fileType: AVFileType.mov)
        
        guard videoWriter.canApply(outputSettings: renderSettings.avOutputSettings, forMediaType: AVMediaType.video) else {
            throw NSError(domain: "canApplyOutputSettings() failed", code: 0, userInfo: nil)
        }
        
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        } else {
            throw NSError(domain: "canAddInput() returned false", code: 1, userInfo: nil)
        }
        videoWriter.shouldOptimizeForNetworkUse = false
        if videoWriter.startWriting() == false {
            throw NSError(domain: "startWriting() failed, \(String(describing: videoWriter.error))", code: 2, userInfo: nil)
        }
        
        videoWriter.startSession(atSourceTime: CMTime.zero)
        self.assetWriter = videoWriter
    }
    
    func render(appendPixelBuffers: @escaping Handler, completion: @escaping () -> Void) {
        let queue = DispatchQueue(label: UUID().uuidString)
        var appendedImageCount: CMTimeValue = 0
        do {
            try start()
            finishBlock = { [weak self] in
                guard let self = self else { return }
                self.finishBlock = nil
                self.videoWriterInput.markAsFinished()
                self.assetWriter.finishWriting(completionHandler: completion)
            }
            videoWriterInput.requestMediaDataWhenReady(on: queue) {
                let compositionTime: CMTime = CMTime(value: appendedImageCount, timescale: self.renderSettings.duration.timescale)
                let isFinished = appendPixelBuffers(compositionTime) { (feedImage: UIImage) in
                    if let pixelBuffer = self.pixelBufferFromImage(image: feedImage) {
                        self.pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: compositionTime)
                        appendedImageCount += 1
                    }
                }
                if isFinished {
                    self.finish()
                } else {
                    
                }
            }
        } catch let error {
            completion()
            log.error(error)
        }
    }
    
    func finish() {
        finishBlock?()
    }
    
}
