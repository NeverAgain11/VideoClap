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
    
    public var renderTarget: VCRenderTarget = VCOfflineRenderTarget()
    
    public func handle(item: VCRequestItem, compositionTime: CMTime, blackImage: CIImage, finish: (CIImage?) -> Void) {
        self.compositionTime = compositionTime
        var preprocessFinishedImages: [String:CIImage] = [:]
        for imageTrack in item.instruction.trackBundle.imageTracks {
            let compensateTimeRange: CMTimeRange? = item.instruction.trackCompensateTimeRange[imageTrack.id]
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
            let compensateTimeRange: CMTimeRange? = item.instruction.trackCompensateTimeRange[imageTrack.id]
            var image: CIImage? = item.sourceFrameDic[imageTrack.id]
            
            if image == nil, let compensateTimeRange = compensateTimeRange {
                if compensateTimeRange.end > imageTrack.timeRange.end {
                    image = imageTrack.originImage(time: imageTrack.sourceTimeRange.end,
                                                         renderSize: self.videoDescription.renderSize,
                                                         renderScale: self.videoDescription.renderScale,
                                                         compensateTimeRange: compensateTimeRange)
                    

                } else if compensateTimeRange.start < imageTrack.timeRange.start {
                    image = imageTrack.originImage(time: imageTrack.sourceTimeRange.start,
                                                         renderSize: self.videoDescription.renderSize,
                                                         renderScale: self.videoDescription.renderScale,
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
            
            guard let fromImage = preprocessFinishedImages[transition.fromId] else { continue }
            guard let toImage = preprocessFinishedImages[transition.toId] else { continue }
            guard let image = transition.transition.transition(renderSize: self.videoDescription.renderSize.scaling(self.videoDescription.renderScale),
                                                               progress: Float(progress),
                                                               fromImage: fromImage,
                                                               toImage: toImage) else {
                continue
            }
            let key = transition.fromId + "🔗" + transition.toId
            image.indexPath = min(fromImage.indexPath, toImage.indexPath)
            preprocessFinishedImages[key] = image
            preprocessFinishedImages.removeValue(forKey: transition.fromId)
            preprocessFinishedImages.removeValue(forKey: transition.toId)
        }
        
        let finalFrame: CIImage? = renderTarget.draw(images: preprocessFinishedImages, blackImage: self.blackImage)
        
        finish(finalFrame)
    }
    
    public func handle(audios: [String : VCAudioTrackDescription],
                       trackID: String,
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
        
        guard let audioTrack = audios[trackID], let url = audioTrack.mediaURL else { return }

        if #available(iOS 11.0, *), let audioEffectProvider = audioTrack.audioEffectProvider {
            do {
                let audioFile = try AVAudioFile(forReading: url)
                let pcmFormat = audioFile.processingFormat
                audioEffectProvider.handle(timeRange: timeRange,
                                           inCount: inCount,
                                           inFlag: inFlag,
                                           outBuffer: outBuffer,
                                           outCount: outCount,
                                           outFlag: outFlag,
                                           pcmFormat: pcmFormat)
            } catch let error {
                log.error(error)
            }
        }
    }

}
