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

    public override func play() {
        super.play()
        let frameDuration = 1.0 / videoDescription.fps
        (currentItem?.customVideoCompositor as? VCRealTimeRenderVideoCompositing)?.tryStartTimer(frameDuration: frameDuration)
    }
    
    public override func pause() {
        super.pause()
        (currentItem?.customVideoCompositor as? VCRealTimeRenderVideoCompositing)?.stopTimer()
        (currentItem?.customVideoCompositor as? VCRealTimeRenderVideoCompositing)?.cancelAllPendingVideoCompositionRequests()
    }
    
    /// 重新构建一个新的player item并替换掉当前的item
    /// - Parameters:
    ///   - time: 要索引的时间，如果该参数nil，则会自动将新的player item索引到原来player item的时间，如果不为nil，新的player item会索引到该时间（范围在0到player item的时长）
    ///   - closure: 构建失败或者替换掉当前的item失败，返回nil，否则返回player item的索引时间
    public func reload(time: CMTime? = nil, closure: ((CMTime?) -> Void)? = nil) {
        do {
            super.pause()
            self.currentItem?.cancelPendingSeeks()
            self.cancelPendingPrerolls()
            self.removePlayingTimeObserver()
            
            let oldRequestCallbackHandler = videoClap.requestCallbackHandler
            oldRequestCallbackHandler.renderTarget = nil

            let newRequestCallbackHandler = VCRequestCallbackHandler()
            newRequestCallbackHandler.renderTarget = realTimeRenderTarget
            videoClap.requestCallbackHandler = newRequestCallbackHandler
            
            let newPlayerItem = try self.videoClap.makePlayerItem(customVideoCompositorClass: realTimeRenderTarget?.compositorClass)
            var seekTime = time ?? self.currentTime()
            seekTime = CMTimeClampToRange(seekTime, range: CMTimeRange(start: .zero, duration: newPlayerItem.duration))
            newPlayerItem.seek(to: seekTime.isValid ? seekTime : .zero, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] (finished) in
                guard let self = self else { return }
                self.replaceCurrentItem(with: newPlayerItem)
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
    
    /// 刷新当前帧，调用此方法会暂停视频的播放
    /// - Returns: 当暂停播放失败或者currentItem为nil的时候返回false，刷新当前帧失败
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
