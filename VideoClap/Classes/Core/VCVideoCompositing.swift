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

internal class VCVideoCompositing: NSObject, AVVideoCompositing {

    internal typealias RequestCallback = (_ items: [VCRequestItem],
                                          _ compositionTime: CMTime,
                                          _ blackImage: CIImage,
                                          _ finish: (CIImage?) -> Void) -> Void
    
    internal let sourcePixelBufferAttributes: [String : Any]? = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                                                 String(kCVPixelBufferOpenGLESCompatibilityKey): true]
    
    internal let requiredPixelBufferAttributesForRenderContext: [String : Any] = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                                                                  String(kCVPixelBufferOpenGLESCompatibilityKey): true]
    
    private let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    private var renderContext: AVVideoCompositionRenderContext = .init()
    
    private lazy var ciContext: CIContext = {
        if let gpu = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: gpu)
        }
        if let eaglContext = EAGLContext(api: .openGLES3) ?? EAGLContext(api: .openGLES2) {
            return CIContext(eaglContext: eaglContext)
        }
        return CIContext()
    }()
    
    private var blackImage: CIImage {
        VCHelper.image(color: .black, size: renderContext.size.scaling(renderContext.renderScale))
    }
    
    internal func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        self.renderContext = newRenderContext
    }
    
    internal func startRequest(_ videoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
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
                                        blackImage: blackImage) { (optionalImage: CIImage?) in
                let image = optionalImage ?? self.blackImage
                if let buffer = self.generateFinalBuffer(ciImage: image) {
                    videoCompositionRequest.finish(withComposedVideoFrame: buffer)
                } else {
                    videoCompositionRequest.finish(with: VCVideoCompositingError.internalError)
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
                         bounds: CGRect(origin: .zero, size: renderContext.size.scaling(renderContext.renderScale)),
                         colorSpace: colorSpace)
        return finalBuffer
    }
    
}

