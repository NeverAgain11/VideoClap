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
    
    internal let sourcePixelBufferAttributes: [String : Any]? = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                                                                 String(kCVPixelBufferOpenGLESCompatibilityKey): true]
    
    internal let requiredPixelBufferAttributesForRenderContext: [String : Any] = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
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
    
    private var blackImage: CIImage = CIImage()
    
    internal func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        self.renderContext = newRenderContext
        setBlackImage()
    }
    
    internal func startRequest(_ videoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        guard let instruction = videoCompositionRequest.videoCompositionInstruction as? VCVideoInstruction else {
            videoCompositionRequest.finish(with: VCVideoCompositingError.internalError)
            return
        }

        var items: [VCRequestItem] = []
        for track: VCTrack in instruction.tracks {
            if track.persistentTrackID == VCVideoCompositor.EmptyVideoTrackID { // 如果是空白的视频轨道，表示音频的时间比视频的时间要长，则不应该再继续处理，应该渲染黑色的画面
                if let buffer = self.generateFinalBuffer(ciImage: self.blackImage) {
                    videoCompositionRequest.finish(withComposedVideoFrame: buffer)
                } else {
                    videoCompositionRequest.finish(with: VCVideoCompositingError.internalError)
                }
                return
            }
            switch track.trackType {
            case .stillImage:
                if let image = track.image() {
                    let item = VCRequestItem(frame: image, id: track.id)
                    items.append(item)
                }
                
            case .video:
                if let sourceFrame = videoCompositionRequest.sourceFrame(byTrackID: track.persistentTrackID) {
                    let sourceImage = CIImage(cvPixelBuffer: sourceFrame)
                    let item = VCRequestItem(frame: sourceImage, id: track.id)
                    items.append(item)
                }
                
            default:
                break
            }
        }
        
        instruction.videoProcessProtocol?.handle(items: items,
                                                 compositionTime: videoCompositionRequest.compositionTime,
                                                 blackImage: blackImage,
                                                 finish: { (optionalImage: CIImage?) in
                                                    let image = optionalImage ?? self.blackImage
                                                    if let buffer = self.generateFinalBuffer(ciImage: image) {
                                                        videoCompositionRequest.finish(withComposedVideoFrame: buffer)
                                                    } else {
                                                        videoCompositionRequest.finish(with: VCVideoCompositingError.internalError)
                                                    }
                                                 })
    }
 
    private func generateFinalBuffer(ciImage: CIImage) -> CVPixelBuffer? {
        guard let finalBuffer: CVPixelBuffer = renderContext.newPixelBuffer() else { return nil }
        
        ciContext.render(ciImage, to: finalBuffer,
                         bounds: CGRect(origin: .zero, size: renderContext.size),
                         colorSpace: colorSpace)
        return finalBuffer
    }
    
    private func setBlackImage() {
        let renderer = VCGraphicsRenderer()
        renderer.rendererRect.size = renderContext.size
        self.blackImage = renderer.ciImage { (context) in
            UIColor.black.setFill()
            UIRectFill(renderer.rendererRect)
        }
    }
    
}

