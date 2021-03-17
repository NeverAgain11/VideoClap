//
//  VCRequestCallbackHandler.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/22.
//

import AVFoundation

open class VCRequestCallbackHandler: NSObject, VCRequestCallbackHandlerProtocol {
    
    public var videoDescription: VCVideoDescription = VCVideoDescription()
    
    public internal(set) var compositionTime: CMTime = .zero
    
    internal var blackImage: CIImage {
        return VCHelper.image(color: .black, size: videoDescription.renderSize.scaling(videoDescription.renderScale))
    }
    
    public weak var renderTarget: VCRenderTarget?
    
    public func handle(item: VCRequestItem, compositionTime: CMTime, blackImage: CIImage, finish: (CIImage?) -> Void) {
        self.compositionTime = compositionTime
        guard let renderTarget = self.renderTarget else {
            finish(nil)
            return
        }
        var preprocessFinishedImages: [String:CIImage] = [:]
        for imageTrack in item.instruction.trackBundle.imageTracks {
            let compensateTimeRange: CMTimeRange? = imageTrack.trackCompensateTimeRange
            let time = CMTimeSubtract(compositionTime, imageTrack.timeRange.start)
            
            guard var image = imageTrack.originImage(time: time,
                                                     renderSize: self.videoDescription.renderSize,
                                                     renderScale: self.videoDescription.renderScale,
                                                     compensateTimeRange: compensateTimeRange) else {
                continue
            }
            image = imageTrack.compositionImage(sourceFrame: image,
                                                compositionTime: compositionTime,
                                                renderSize: self.videoDescription.renderSize,
                                                renderScale: self.videoDescription.renderScale,
                                                compensateTimeRange: compensateTimeRange) ?? image
            image.indexPath = imageTrack.indexPath
            preprocessFinishedImages[imageTrack.id] = image
        }
        
        for imageTrack in item.instruction.trackBundle.videoTracks {
            let compensateTimeRange: CMTimeRange? = imageTrack.trackCompensateTimeRange
            var image: CIImage? = item.sourceFrameDic[imageTrack.id]
            
            if image == nil, let compensateTimeRange = compensateTimeRange {
                if compensateTimeRange.end > imageTrack.timeRange.end {
                    image = imageTrack.originImage(time: imageTrack.sourceTimeRange.end,
                                                         compensateTimeRange: compensateTimeRange)
                    

                } else if compensateTimeRange.start < imageTrack.timeRange.start {
                    image = imageTrack.originImage(time: imageTrack.sourceTimeRange.start,
                                                         compensateTimeRange: compensateTimeRange)
                }
            }
            
            if image == nil {
                continue
            }
            
            image = imageTrack.compositionImage(sourceFrame: image.unsafelyUnwrapped,
                                                compositionTime: compositionTime,
                                                renderSize: self.videoDescription.renderSize,
                                                renderScale: self.videoDescription.renderScale,
                                                compensateTimeRange: compensateTimeRange)
            image.unsafelyUnwrapped.indexPath = imageTrack.indexPath
            preprocessFinishedImages[imageTrack.id] = image
        }
        
        for transition in item.instruction.transitions {
            let progress = (compositionTime.seconds - transition.timeRange.start.seconds) / transition.timeRange.duration.seconds
            if progress.isNaN {
                continue
            }
            guard let fromTrack = transition.fromTrack else { continue }
            guard let toTrack = transition.toTrack else { continue }
            guard let fromImage = preprocessFinishedImages[fromTrack.id] else { continue }
            guard let toImage = preprocessFinishedImages[toTrack.id] else { continue }
            guard let image = transition.transition.transition(renderSize: self.videoDescription.renderSize.scaling(self.videoDescription.renderScale),
                                                               progress: Float(progress),
                                                               fromImage: fromImage.composited(over: blackImage),
                                                               toImage: toImage.composited(over: blackImage)) else {
                continue
            }
            let key = fromTrack.id + "🔗" + toTrack.id
            image.indexPath = min(fromImage.indexPath, toImage.indexPath)
            preprocessFinishedImages[key] = image
            preprocessFinishedImages.removeValue(forKey: fromTrack.id)
            preprocessFinishedImages.removeValue(forKey: toTrack.id)
        }
        
        let finalFrame: CIImage? = renderTarget.draw(compositionTime: compositionTime,
                                                     images: preprocessFinishedImages,
                                                     blackImage: blackImage,
                                                     renderSize: videoDescription.renderSize,
                                                     renderScale: videoDescription.renderScale)
        finish(finalFrame)
    }
    
    public func handle(audioTrack: VCAudioTrackDescription,
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
