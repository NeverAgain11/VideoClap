//
//  VCRequestCallbackHandler.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/22.
//

import AVFoundation

open class VCRequestCallbackHandler: NSObject, VCRequestCallbackHandlerProtocol {
    
    public weak var renderTarget: VCRenderTarget?
    
    public required override init() {
        super.init()
    }
    
    open func handle(item: VCRequestItem, compositionTime: CMTime, blackImage: CIImage, renderContext: AVVideoCompositionRenderContext, finish: (CIImage?) -> Void) {
        guard let renderTarget = self.renderTarget else {
            finish(nil)
            return
        }
        var preprocessFinishedImages: [String:CIImage] = [:]
        for imageTrack in item.instruction.trackBundle.imageTracks {
            let compensateTimeRange: CMTimeRange? = imageTrack.trackCompensateTimeRange
            let time = CMTimeSubtract(compositionTime, imageTrack.timeRange.start)
            
            guard var image = imageTrack.originImage(time: time,
                                                     renderSize: renderContext.size,
                                                     renderScale: CGFloat(renderContext.renderScale),
                                                     compensateTimeRange: compensateTimeRange) else {
                continue
            }
            image = imageTrack.compositionImage(sourceFrame: image,
                                                compositionTime: compositionTime,
                                                renderSize: renderContext.size,
                                                renderScale: CGFloat(renderContext.renderScale),
                                                compensateTimeRange: compensateTimeRange) ?? image
            image.indexPath = imageTrack.indexPath
            preprocessFinishedImages[imageTrack.id] = image
        }
        
        for imageTrack in item.instruction.trackBundle.videoTracks {
            guard var image = item.sourceFrameDic[imageTrack.id] else {
                continue
            }
            let compensateTimeRange: CMTimeRange? = imageTrack.trackCompensateTimeRange
            image = imageTrack.compositionImage(sourceFrame: image,
                                                compositionTime: compositionTime,
                                                renderSize: renderContext.size,
                                                renderScale: CGFloat(renderContext.renderScale),
                                                compensateTimeRange: compensateTimeRange) ?? image
            image.indexPath = imageTrack.indexPath
            preprocessFinishedImages[imageTrack.id] = image
        }
        
        for transition in item.instruction.transitions {
            guard let fromTrack = transition.fromTrack else { continue }
            guard let toTrack = transition.toTrack else { continue }
            let fromImage: CIImage? = preprocessFinishedImages[fromTrack.id]
            let toImage: CIImage? = preprocessFinishedImages[toTrack.id]
            
            if let image = transition.transition(compositionTime: compositionTime, fromImage: fromImage, toImage: toImage, renderSize: renderContext.size, renderScale: CGFloat(renderContext.renderScale)) {
                let key = fromTrack.id + "🔗" + toTrack.id
                image.indexPath = min(fromTrack.indexPath, toTrack.indexPath)
                preprocessFinishedImages[key] = image
                preprocessFinishedImages.removeValue(forKey: fromTrack.id)
                preprocessFinishedImages.removeValue(forKey: toTrack.id)
            }
        }
        let finalFrame: CIImage? = renderTarget.draw(compositionTime: compositionTime,
                                                     images: preprocessFinishedImages,
                                                     blackImage: blackImage,
                                                     renderSize: renderContext.size,
                                                     renderScale: CGFloat(renderContext.renderScale))
        finish(finalFrame)
    }
    
    open func handle(audioTrack: VCAudioTrackDescription,
                       timeRange: CMTimeRange,
                       inCount: CMItemCount,
                       inFlag: MTAudioProcessingTapFlags,
                       outBuffer: UnsafeMutablePointer<AudioBufferList>,
                       outCount: UnsafeMutablePointer<CMItemCount>,
                       outFlag: UnsafeMutablePointer<MTAudioProcessingTapFlags>,
                       error: VCAudioProcessingTapError?) {
        guard error == nil else {
            return
        }
        
        if let audioEffectProvider = audioTrack.audioEffectProvider, let pcmFormat = audioTrack.processingFormat {
            audioEffectProvider.handle(timeRange: timeRange,
                                       inCount: inCount,
                                       inFlag: inFlag,
                                       outBuffer: outBuffer,
                                       outCount: outCount,
                                       outFlag: outFlag,
                                       pcmFormat: pcmFormat)
        }
    }

}
