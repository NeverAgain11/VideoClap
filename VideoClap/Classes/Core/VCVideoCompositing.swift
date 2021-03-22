//
//  VCVideoCompositing.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import Foundation
import GLKit
import AVFoundation

internal enum VCVideoCompositingError: Error {
    case internalError
}

public class VCVideoCompositing: NSObject, AVVideoCompositing {

    internal typealias RequestCallback = (_ items: [VCRequestItem],
                                          _ compositionTime: CMTime,
                                          _ blackImage: CIImage,
                                          _ finish: (CIImage?) -> Void) -> Void
    
    public let sourcePixelBufferAttributes: [String : Any]? = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                                                 String(kCVPixelBufferOpenGLESCompatibilityKey): true]
    
    public let requiredPixelBufferAttributesForRenderContext: [String : Any] = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                                                                  String(kCVPixelBufferOpenGLESCompatibilityKey): true]
    
    private let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    private var renderContext: AVVideoCompositionRenderContext = .init()
    
    private var actualRenderSize: CGSize = .zero
    
    private var ciContext: CIContext = CIContext.share
    
    private var blackImage: CIImage {
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
                    if let buffer = self.generateFinalBuffer(ciImage: image) {
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
            if let buffer = self.generateFinalBuffer(ciImage: image) {
                videoCompositionRequest.finish(withComposedVideoFrame: buffer)
            } else {
                videoCompositionRequest.finish(with: VCVideoCompositingError.internalError)
            }
        }
    }
 
    private func generateFinalBuffer(ciImage: CIImage) -> CVPixelBuffer? {
        guard let finalBuffer: CVPixelBuffer = renderContext.newPixelBuffer() else { return nil }
        
        ciContext.render(ciImage, to: finalBuffer,
                         bounds: CGRect(origin: .zero, size: actualRenderSize),
                         colorSpace: colorSpace)
        return finalBuffer
    }
    
}

public class VCRealTimeRenderVideoCompositing: VCVideoCompositing {
    
    private var pendingVideoCompositionRequests: [AVAsynchronousVideoCompositionRequest] = []
    
    private var timer: Timer?
    
    private var locker: NSLock = .init()
    
    private var queueLocker: DispatchSemaphore = .init(value: 1)
    
    private var timerQueue: DispatchQueue = .init(label: "timer", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    
    deinit {
        timer?.invalidate()
        timer = nil
        cancelAllPendingVideoCompositionRequests()
    }
    
    public override func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        super.renderContextChanged(newRenderContext)
        cancelAllPendingVideoCompositionRequests()
        stopTimer()
        tryStartTimer(frameDuration: newRenderContext.videoComposition.frameDuration.seconds)
    }
    
    public override func startRequest(_ videoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        if timer == nil {
            processRequest(videoCompositionRequest)
        } else {
            enqueue(request: videoCompositionRequest)
        }
    }
    
    @objc internal func timerTick(_ timer: Timer) {
        if let request = dequeue() {
            processRequest(request)
        }
    }
    
    internal func startTimer(frameDuration: TimeInterval) {
        timerQueue.async { [unowned self] in
            self.timer = Timer.every(frameDuration) { [weak self] (timer) in
                guard let self = self else { return }
                self.timerTick(timer)
            }
            self.timer?.start(runLoop: .current, modes: .tracking, .default, .common)
            RunLoop.current.run()
        }
    }
    
    internal func stopTimer() {
        timerQueue.async { [unowned self] in
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    internal func tryStartTimer(frameDuration: TimeInterval) {
        timerQueue.async { [unowned self] in
            guard self.timer == nil else {
                return
            }
            self.timer = Timer.every(frameDuration) { [weak self] (timer) in
                guard let self = self else { return }
                self.timerTick(timer)
            }
            self.timer?.start(runLoop: .current, modes: .tracking, .default, .common)
            RunLoop.current.run()
        }
    }
    
    private func enqueue(request: AVAsynchronousVideoCompositionRequest) {
        queueLocker.wait()
        defer {
            queueLocker.signal()
        }
        pendingVideoCompositionRequests.append(request)
    }
    
    private func dequeue() -> AVAsynchronousVideoCompositionRequest? {
        queueLocker.wait()
        defer {
            queueLocker.signal()
        }
        guard pendingVideoCompositionRequests.isEmpty == false else {
            return nil
        }
        let first = pendingVideoCompositionRequests.removeFirst()
        return first
    }
    
    internal func cancelAllPendingVideoCompositionRequests() {
        locker.lock()
        defer {
            locker.unlock()
        }
        for videoCompositionRequest in pendingVideoCompositionRequests {
            videoCompositionRequest.finishCancelledRequest()
        }
        self.pendingVideoCompositionRequests = []
    }
    
}
