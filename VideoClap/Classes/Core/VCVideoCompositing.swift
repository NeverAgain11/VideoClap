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
    
//    private var lastRequestTime: TimeInterval?
    
    public override func startRequest(_ videoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        let start = CFAbsoluteTimeGetCurrent()
//        var timeCorrection: TimeInterval = 0
//        if let _lastRequestTime = lastRequestTime {
//            timeCorrection = start - _lastRequestTime
//        }
        processRequest(videoCompositionRequest)
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
