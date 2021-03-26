//
//  VCPlayer.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/15.
//

import SSPlayer
import AVFoundation

public class VCPlayer: SSPlayer {
    
    private lazy var videoClap: VideoClap = {
        let videoClap = VideoClap()
        
        return videoClap
    }()
    
    public var videoDescription: VCVideoDescription {
        return videoClap.videoDescription
    }
    
    private var playingBlock: ((_ time: CMTime) -> Void)?
    
    private var interval: CMTime = .init(seconds: 1/30)
    
    private var observeQueue: DispatchQueue = .main
    
    public var offlineRenderTarget: VCRenderTarget = VCOfflineRenderTarget()
    
    public weak var realTimeRenderTarget: VCRealTimeRenderTarget? {
        didSet {
            videoClap.requestCallbackHandler.renderTarget = realTimeRenderTarget
        }
    }
    
    public var customRequestCallbackHandlerClass: VCRequestCallbackHandler.Type = VCRequestCallbackHandler.self {
        didSet {
            let oldRequestCallbackHandler = videoClap.requestCallbackHandler
            oldRequestCallbackHandler.renderTarget = nil
            
            let newRequestCallbackHandler = customRequestCallbackHandlerClass.init()
            newRequestCallbackHandler.renderTarget = realTimeRenderTarget
            videoClap.requestCallbackHandler = newRequestCallbackHandler
        }
    }
    
    public override func replaceCurrentItem(with item: AVPlayerItem?) {
        super.replaceCurrentItem(with: item)
        realTimeRenderTarget?.didReplacePlayerItem(item)
    }
    
    public override func play() {
        super.play()
        realTimeRenderTarget?.onPlay()
    }
    
    public override func pause() {
        super.pause()
        realTimeRenderTarget?.onPause()
    }
    
    /// Rebuild a new player item and replace the current item
    /// - Parameters:
    ///   - time: If the parameter is nil, the new player item will automatically seek to the time of the original player item, If it is not nil, the new player item will seek to the time (range zero to the duration of the player item)
    ///   - closure: return nil If the construction fails, otherwise the seek time of the player item is returned
    public func reload(time: CMTime? = nil, closure: ((CMTime?) -> Void)? = nil) {
        do {
            super.pause()
            self.currentItem?.cancelPendingSeeks()
            self.cancelPendingPrerolls()
            self.removePlayingTimeObserver()
            
            let oldRequestCallbackHandler = videoClap.requestCallbackHandler
            oldRequestCallbackHandler.renderTarget = nil
            
            let newRequestCallbackHandler = customRequestCallbackHandlerClass.init()
            newRequestCallbackHandler.renderTarget = realTimeRenderTarget
            videoClap.requestCallbackHandler = newRequestCallbackHandler
            
            let newPlayerItem = try self.videoClap.makePlayerItem(customVideoCompositorClass: realTimeRenderTarget?.compositorClass)
            var seekTime = time ?? self.currentTime()
            seekTime = CMTimeClampToRange(seekTime, range: CMTimeRange(start: .zero, duration: newPlayerItem.duration))
            self.replaceCurrentItem(with: newPlayerItem)
            newPlayerItem.seek(to: seekTime.isValid ? seekTime : .zero, toleranceBefore: .zero, toleranceAfter: .zero) { (finished) in
                if finished {
                    closure?(seekTime)
                } else {
                    closure?(nil)
                }
            }
            if let block = self.playingBlock {
                self.observePlayingTime(forInterval: self.interval, queue: self.observeQueue, block: block)
            }
        } catch let error {
            log.error(error)
            closure?(nil)
        }
    }
    
    /// Refresh the current frame, calling this method will pause the video playback
    /// - Returns: When pause playback fails or currentItem is nil, it returns false, refreshing the current frame fails
    @discardableResult public func reloadFrame() -> Bool {
        super.pause()
        if isPlaying {
            return false
        }
        guard let item = currentItem else { return false }
        guard let videoComposition = item.videoComposition?.mutableCopy() as? AVMutableVideoComposition else { return false }
        #if !targetEnvironment(simulator)
        if #available(iOS 10.0, *) {
        videoComposition.colorPrimaries = videoDescription.colorPrimaries
        videoComposition.colorTransferFunction = videoDescription.colorTransferFunction
        videoComposition.colorYCbCrMatrix = videoDescription.colorYCbCrMatrix
        }
        #endif
        videoComposition.frameDuration = CMTime(seconds: 1 / videoDescription.fps, preferredTimescale: 600)
        videoComposition.renderSize = videoDescription.renderSize
        videoComposition.renderScale = Float(videoDescription.renderScale)
        item.videoComposition = videoComposition
        return true
    }
    
    public override func observePlayingTime(forInterval interval: CMTime = CMTime(value: 30, timescale: 600), queue: DispatchQueue = .main, block: @escaping (CMTime) -> Void) {
        self.playingBlock = block
        self.observeQueue = queue
        self.interval = interval
        super.observePlayingTime(forInterval: interval, queue: queue, block: block)
    }
    
    public func export(size: CGSize? = nil, fileName: String? = nil, progressHandler: @escaping ProgressHandler, completionHandler: @escaping ((URL?, Error?) -> Void)) -> CancelClosure? {
        let renderSize = videoClap.videoDescription.renderSize
        let renderScale = videoClap.videoDescription.renderScale
        let exportRenderSize = size ?? renderSize.scaling(renderScale)

        let asset = (currentItem?.asset as! AVMutableComposition).mutableCopy() as! AVAsset
        let audioMix = currentItem?.audioMix?.mutableCopy() as? AVAudioMix
        let videoComposition = currentItem?.videoComposition?.mutableCopy() as? AVMutableVideoComposition
        videoComposition?.renderSize = exportRenderSize
        videoComposition?.renderScale = 1.0
        videoComposition?.customVideoCompositorClass = VCVideoCompositing.self

        videoClap.requestCallbackHandler.renderTarget = offlineRenderTarget
        return videoClap.export(asset: asset, audioMix: audioMix, videoComposition: videoComposition, progressHandler: progressHandler) { [weak self] url, error in
            self?.videoClap.requestCallbackHandler.renderTarget = self?.realTimeRenderTarget
            completionHandler(url, error)
        }
    }
    
    public func estimateVideoDuration() -> CMTime {
        return (try? videoClap.makePlayerItem().asset.duration) ?? .zero
    }
    
}
