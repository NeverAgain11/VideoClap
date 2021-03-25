//
//  VCVideoCompositing.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import Foundation
import GLKit
import AVFoundation
import VideoToolbox

internal enum VCVideoCompositingError: Error {
    case internalError
}

public class VCVideoCompositing: NSObject, AVVideoCompositing {
    
    public static var defaultSourcePixelBufferAttributes: [String : Any]? = {
        var pixelBufferAttributes: [String : Any] = [:]
        pixelBufferAttributes[String(kCVPixelBufferPixelFormatTypeKey)] = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        pixelBufferAttributes[String(kCVPixelBufferOpenGLESCompatibilityKey)] = kCFBooleanTrue
        return pixelBufferAttributes.isEmpty ? nil : pixelBufferAttributes
    }()
    
    public static var defaultRequiredPixelBufferAttributesForRenderContext: [String : Any] = {
        var pixelBufferAttributes: [String : Any] = [:]
        pixelBufferAttributes[String(kCVPixelBufferPixelFormatTypeKey)] = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        pixelBufferAttributes[String(kCVPixelBufferOpenGLESCompatibilityKey)] = kCFBooleanTrue
        return pixelBufferAttributes
    }()
    
    internal typealias RequestCallback = (_ items: [VCRequestItem],
                                          _ compositionTime: CMTime,
                                          _ blackImage: CIImage,
                                          _ finish: (CIImage?) -> Void) -> Void
    
    public let sourcePixelBufferAttributes = VCVideoCompositing.defaultSourcePixelBufferAttributes
    
    public let requiredPixelBufferAttributesForRenderContext = VCVideoCompositing.defaultRequiredPixelBufferAttributesForRenderContext
    
    private let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    private(set) var renderContext: AVVideoCompositionRenderContext = .init()
    
    private(set) var actualRenderSize: CGSize = .zero
    
    private var ciContext: CIContext = CIContext.share
    
    internal var blackImage: CIImage {
        return VCHelper.image(color: .black, size: actualRenderSize)
    }
    
    public func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        self.renderContext = newRenderContext
        self.actualRenderSize = newRenderContext.size.scaling(newRenderContext.renderScale)
    }
    
    public func startRequest(_ videoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        processRequest(videoCompositionRequest)
    }
    
    internal func processRequest(_ videoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        guard let instruction = videoCompositionRequest.videoCompositionInstruction as? VCVideoInstruction else {
            videoCompositionRequest.finish(with: VCVideoCompositingError.internalError)
            return
        }
        let pts = videoCompositionRequest.compositionTime
        if let videoProcessProtocol = instruction.videoProcessProtocol {
            let item = VCRequestItem()
            item.instruction = instruction
            
            for (persistentTrackID, videoTrackDescription) in instruction.requiredSourceTrackIDsDic {
                if let sourceFrame = videoCompositionRequest.sourceFrame(byTrackID: persistentTrackID) {
                    let sourceImage = CIImage(cvPixelBuffer: sourceFrame)
                    item.sourceFrameDic[videoTrackDescription.id] = sourceImage
                }
            }
            videoProcessProtocol.handle(item: item,
                                        compositionTime: videoCompositionRequest.compositionTime,
                                        blackImage: blackImage,
                                        renderContext: renderContext) { (optionalImage: CIImage?) in
                if let image = optionalImage {
                    if let buffer = self.generateFinalBuffer(pts: pts, ciImage: image) {
                        videoCompositionRequest.finish(withComposedVideoFrame: buffer)
                    } else {
                        videoCompositionRequest.finish(with: VCVideoCompositingError.internalError)
                    }
                } else {
                    if let id = videoCompositionRequest.sourceTrackIDs.first as? CMPersistentTrackID,
                       let frame = videoCompositionRequest.sourceFrame(byTrackID: id) {
                        videoCompositionRequest.finish(withComposedVideoFrame: frame)
                    } else {
                        videoCompositionRequest.finish(with: VCVideoCompositingError.internalError)
                    }
                }
            }
        } else {
            let image = self.blackImage
            if let buffer = self.generateFinalBuffer(pts: pts, ciImage: image) {
                videoCompositionRequest.finish(withComposedVideoFrame: buffer)
            } else {
                videoCompositionRequest.finish(with: VCVideoCompositingError.internalError)
            }
        }
    }
 
    internal func generateFinalBuffer(pts: CMTime, ciImage: CIImage) -> CVPixelBuffer? {
        guard let finalBuffer: CVPixelBuffer = renderContext.newPixelBuffer() else { return nil }
        
        ciContext.render(ciImage, to: finalBuffer,
                         bounds: CGRect(origin: .zero, size: actualRenderSize),
                         colorSpace: colorSpace)
        return finalBuffer
    }
    
}

public class VCRealTimeRenderVideoCompositing: VCVideoCompositing {
    
//    private var lastRequestTime: TimeInterval?
    
    public override func startRequest(_ videoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        let start = CFAbsoluteTimeGetCurrent()
//        var timeCorrection: TimeInterval = 0
//        if let _lastRequestTime = lastRequestTime {
//            timeCorrection = start - _lastRequestTime
//        }
        super.startRequest(videoCompositionRequest)
        let end = CFAbsoluteTimeGetCurrent()
        let processTime = end - start
        if processTime >= renderContext.videoComposition.frameDuration.seconds {

        } else {
//            let sleepTime = renderContext.videoComposition.frameDuration.seconds - processTime - timeCorrection
            let sleepTime = renderContext.videoComposition.frameDuration.seconds - processTime
            Thread.sleep(forTimeInterval: sleepTime)
        }
//        lastRequestTime = CFAbsoluteTimeGetCurrent()
    }
    
}

public class VCVideoCacheCompositing: VCVideoCompositing {
    
    internal var compositingCache: VCVideoCompositingCacheProtocol?
    
    public override func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        super.renderContextChanged(newRenderContext)
        resetCache()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForeground(_:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    public override func startRequest(_ videoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        if let _compositingCache = self.compositingCache {
            _compositingCache.buffer(pts: videoCompositionRequest.compositionTime) { (buffer: CVPixelBuffer?) in
                if let _buffer = buffer {
                    videoCompositionRequest.finish(withComposedVideoFrame: _buffer)
                } else {
                    self.processRequest(videoCompositionRequest)
                }
            }
        } else {
            self.processRequest(videoCompositionRequest)
        }
    }
    
    override func generateFinalBuffer(pts: CMTime, ciImage: CIImage) -> CVPixelBuffer? {
        if let buffer = super.generateFinalBuffer(pts: pts, ciImage: ciImage) {
            compositingCache?.storeBuffer(buffer, pts: pts, closure: nil)
            return buffer
        } else {
            return nil
        }
    }
    
    @objc func willEnterForeground(_ sender: Notification) {
        resetCache()
    }
    
    public func resetCache() {
        let cache = VCVideoCompositingCache(compositing: self)
        cache.setup()
        self.compositingCache = cache
    }
    
}

public protocol VCVideoCompositingCacheProtocol: NSObject {
    func buffer(pts: CMTime, closure: @escaping (CVPixelBuffer?) -> Void)
    func storeBuffer(_ buffer: CVPixelBuffer, pts: CMTime, closure: ((Bool) -> Void)?)
}

public class VCVideoCompositingCache: NSObject, VCVideoCompositingCacheProtocol, VCEncoderDelegate, VCDecoderDelegate {
    
    private var encoder: VCEncoder = VCEncoder()
    
    private var decoder: VCDecoder?
    
    internal weak var compositing: VCVideoCompositing?
    
    private var cache: NSCache<NSString, CMSampleBuffer> = .init()
    
    private var decodedBuffer: CVPixelBuffer?
    
    public init(compositing: VCVideoCompositing) {
        self.compositing = compositing
        super.init()
        self.encoder.delegate = self
    }
    
    deinit {
        try? encoder.stopEncoder()
        try? decoder?.stopDecoder()
        cache.removeAllObjects()
    }
    
    public func setup() {
        guard let compositing = self.compositing else { return }
        do {
            encoder.encodeWidth = Int32(compositing.actualRenderSize.width)
            encoder.encodeHeight = Int32(compositing.actualRenderSize.height)
            encoder.pixelFormat = compositing.requiredPixelBufferAttributesForRenderContext[String(kCVPixelBufferPixelFormatTypeKey)] as? OSType ?? kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
            encoder.frameRate = CFIndex(1.0 / compositing.renderContext.videoComposition.frameDuration.seconds)
            encoder.bitRate = Int(encoder.encodeWidth * encoder.encodeHeight) * encoder.frameRate
            try encoder.setup()
        } catch let error {
            log.error(error)
        }
    }
    
    public func buffer(pts: CMTime, closure: @escaping (CVPixelBuffer?) -> Void) {
        let key = String(pts.value) as NSString
        if let sampleBuffer = cache.object(forKey: key) {
            do {
                try self.decoder?.decode(sampleBuffer: sampleBuffer)
                closure(self.decodedBuffer)
            } catch {
                closure(nil)
            }
        } else {
            closure(nil)
        }
    }
    
    public func storeBuffer(_ buffer: CVPixelBuffer, pts: CMTime, closure: ((Bool) -> Void)? = nil) {
        self.encode(buffer: buffer, pts: pts)
        closure?(true)
    }
    
    private func encode(buffer: CVPixelBuffer, pts: CMTime) {
        guard let compositing = self.compositing else { return }
        do {
//            let dataSize = CVPixelBufferGetDataSize(buffer)
            try encoder.encode(buffer: buffer,
                               keyFrame: kCFBooleanTrue,
                               pts: pts,
                               duration: compositing.renderContext.videoComposition.frameDuration)
        } catch let error {
            log.error("encode image failed", error)
        }
    }
    
    // MARK: - encoder delegate
    public func encodeFinish(status: OSStatus, infoFlags: VTEncodeInfoFlags, sampleBuffer: CMSampleBuffer?) {
        guard let sampleBuffer = sampleBuffer,
              let compositing = self.compositing,
              CMSampleBufferDataIsReady(sampleBuffer),
              CMSampleBufferIsValid(sampleBuffer),
              status == noErr
        else {
            log.error("encode image failed")
            return
        }
        
//        let sampleSize = CMSampleBufferGetTotalSampleSize(sampleBuffer)
        
//        var isKeyFrame: Bool = false
//        let sampleAttachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true)
//        if let value = CFArrayGetValueAtIndex(sampleAttachments, 0) {
//            let sampleAttachment = Unmanaged<CFDictionary>.fromOpaque(value).takeUnretainedValue()
//            isKeyFrame = CFDictionaryContainsKey(sampleAttachment, Unmanaged.passUnretained(kCMSampleAttachmentKey_NotSync).toOpaque()) == false
//        }
        
        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
        var extensions: CFDictionary?
        if let _formatDescription = formatDescription {
            extensions = CMFormatDescriptionGetExtensions(_formatDescription)
        }
        let pts: CMTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        do {
            if decoder == nil {
                decoder = VCDecoder()
                decoder?.delegate = self
                decoder?.decodeWidth = Int32(compositing.actualRenderSize.width)
                decoder?.decodeHeight = Int32(compositing.actualRenderSize.height)
                decoder?.extensions = extensions
                try decoder?.setup()
            }
            let key = String(pts.value) as NSString
            cache.setObject(sampleBuffer, forKey: key)
        } catch let error {
            log.error(error)
        }
    }
    
    // MARK: - decoder delegate
    public func decodeFinish(status: OSStatus, infoFlags: VTDecodeInfoFlags, imageBuffer: CVImageBuffer?, presentationTimeStamp: CMTime, presentationDuration: CMTime) {
        self.decodedBuffer = imageBuffer
    }
    
}

public class VCVideoCompositingCache2: NSObject, VCVideoCompositingCacheProtocol {
    
    private var cache: NSCache<NSString, CVPixelBuffer> = .init()
    
    deinit {
        cache.removeAllObjects()
    }
    
    public func buffer(pts: CMTime, closure: @escaping (CVPixelBuffer?) -> Void) {
        let key = NSString(string: String(pts.value))
        if let buffer = cache.object(forKey: key) {
            closure(buffer)
        } else {
            closure(nil)
        }
    }
    
    public func storeBuffer(_ buffer: CVPixelBuffer, pts: CMTime, closure: ((Bool) -> Void)?) {
        let key = NSString(string: String(pts.value))
        cache.setObject(buffer, forKey: key)
        closure?(true)
    }
    
}
