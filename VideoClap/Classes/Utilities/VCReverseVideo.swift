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

private class VCReverseVideoRequestCallbackHandler: VCRequestCallbackHandler {
    
    var assetReader: AVAssetReader?
    
    var assetReaderOutput: AVAssetReaderTrackOutput?
    
    var duration: CMTime?
    
    var samples: [CMSampleBuffer] = []
    
    var asset: AVAsset?
    
    var videoTrack: AVAssetTrack?
    
    var lastPts: CMTime?
    
    var lastTimeRange: CMTimeRange?
    
    override func handle(item: VCRequestItem, compositionTime: CMTime, blackImage: CIImage, finish: (CIImage?) -> Void) {

        if samples.isEmpty {
            
            guard let asset = asset, let videoTrack = videoTrack, let duration = duration else {
                finish(nil)
                return
            }
            
            guard let reader = try? AVAssetReader(asset: asset) else {
                finish(nil)
                return
            }
            
            let assetReaderOutput = AVAssetReaderTrackOutput(track: videoTrack,
                                                             outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange])
            assetReaderOutput.supportsRandomAccess = true

            if reader.canAdd(assetReaderOutput) == false {
                finish(nil)
                return
            }

            reader.add(assetReaderOutput)
            
            if let lastTimeRange = lastTimeRange {
                let timeRange = CMTimeRange(start: lastTimeRange.start - CMTime(seconds: 1.0), end: lastTimeRange.start + CMTime(seconds: 0.5))
                reader.timeRange = timeRange
            } else {
                let timeRange = CMTimeRange(start: duration - CMTime(seconds: 1.0), end: duration)
                reader.timeRange = timeRange
            }
            
            lastTimeRange = reader.timeRange
            
            if reader.startReading() == false {
                finish(nil)
                return
            }
            
            var subsamples: [CMSampleBuffer] = []
            
            while true {
                if let buffer = assetReaderOutput.copyNextSampleBuffer() {
                    if let lastPts = lastPts {
                        if CMSampleBufferGetPresentationTimeStamp(buffer) < lastPts {
                            subsamples.append(buffer)
                        }
                    } else {
                        subsamples.append(buffer)
                    }
                } else {
                    break
                }
            }
            subsamples.sort { (lhs, rhs) -> Bool in
                return CMSampleBufferGetPresentationTimeStamp(lhs) < CMSampleBufferGetPresentationTimeStamp(rhs)
            }
            samples.insert(contentsOf: subsamples, at: 0)
        }
        
        if samples.isEmpty {
            finish(nil)
            return
        } else {
            let lastSample = samples.removeLast()
            
            if let imageBuffer = CMSampleBufferGetImageBuffer(lastSample) {
                lastPts = CMSampleBufferGetPresentationTimeStamp(lastSample)
                let ciimage = CIImage(cvImageBuffer: imageBuffer)
                finish(ciimage)
            } else {
                finish(nil)
            }
        }
        
    }
    
}

public class VCReverseVideo: NSObject {
    
    let videoClap = VideoClap()
    
    public func reverse(input inputUrl: URL, progressCallback: @escaping (Progress) -> Void, completionCallback: @escaping (URL?, Error?) -> Void) {
        
        let asset = AVAsset(url: inputUrl)
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return
        }
        
        let customRequestCallbackHandler = VCReverseVideoRequestCallbackHandler()
        customRequestCallbackHandler.asset = asset
        customRequestCallbackHandler.videoTrack = videoTrack
        customRequestCallbackHandler.duration = asset.duration
        
        videoClap.requestCallbackHandler = customRequestCallbackHandler
        videoClap.videoDescription.renderSize = videoTrack.naturalSize
        videoClap.videoDescription.fps = Double(videoTrack.nominalFrameRate)
        
        let videoTrackDes = VCVideoTrackDescription()
        videoTrackDes.id = "reverse"
        let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        videoTrackDes.timeMapping = CMTimeMapping(source: timeRange, target: timeRange)
        
        videoClap.videoDescription.trackBundle.videoTracks.append(videoTrackDes)
        
        videoClap.export { (progress: Progress) in
            progressCallback(progress)
        } completionHandler: { (url: URL?, error: Error?) in
            customRequestCallbackHandler.samples.removeAll()
            completionCallback(url, error)
        }

    }
    
}
