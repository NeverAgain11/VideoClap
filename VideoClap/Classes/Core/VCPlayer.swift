//
//  VCPlayer.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/15.
//

import SSPlayer
import AVFoundation

public enum VCManualRenderingMode: Int {
    case offline = 0
    case realtime = 1
}

public class VCPlayer: SSPlayer, VCRenderTarget {
    
    private lazy var videoClap: VideoClap = {
        let videoClap = VideoClap()
        videoClap.requestCallbackHandler.renderTarget = self
        return videoClap
    }()
    
    public lazy var videoDescription: VCVideoDescription = {
        let des = VCVideoDescription()
        return des
    }()
    
    private var playingBlock: ((_ time: CMTime) -> Void)?
    
    private var interval: CMTime = .init(seconds: 1/30)
    
    private var observeQueue: DispatchQueue = .main
    
    public private(set) var manualRenderingMode: VCManualRenderingMode = .realtime
    
    public var offlineRenderTarget = VCOfflineRenderTarget()
    
    public weak var realTimeRenderTarget: VCRenderTarget?

    public override init() {
        super.init()
        videoClap.videoDescription = self.videoDescription
    }
    
    public func draw(compositionTime: CMTime, images: [String : CIImage], blackImage: CIImage, renderSize: CGSize, renderScale: CGFloat) -> CIImage? {
        var frame: CIImage?
        switch manualRenderingMode {
        case .offline:
            frame = offlineRenderTarget.draw(compositionTime: compositionTime, images: images, blackImage: blackImage, renderSize: renderSize, renderScale: renderScale)
        case .realtime:
            frame = realTimeRenderTarget?.draw(compositionTime: compositionTime, images: images, blackImage: blackImage, renderSize: renderSize, renderScale: renderScale)
        }
        return frame
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
            newRequestCallbackHandler.videoDescription = self.videoDescription
            newRequestCallbackHandler.renderTarget = self
            videoClap.requestCallbackHandler = newRequestCallbackHandler
            
            let newPlayerItem = try self.videoClap.playerItemForPlay()
            var seekTime = time ?? oldRequestCallbackHandler.compositionTime
            seekTime = CMTimeClampToRange(seekTime, range: CMTimeRange(start: .zero, duration: newPlayerItem.duration))
            newPlayerItem.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero) { (finished) in
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
    
    public func enableManualRenderingMode() throws {
        if currentItem == nil {
            throw NSError(domain: "", code: 1, userInfo: [NSLocalizedFailureReasonErrorKey : ""])
        } else {
            videoClap.requestCallbackHandler.renderTarget = offlineRenderTarget
            manualRenderingMode = .offline
            self.removePlayingTimeObserver()
            super.pause()
        }
    }
    
    public func disableManualRenderingMode() {
        guard manualRenderingMode == .offline else {
            return
        }
        videoClap.requestCallbackHandler.renderTarget = self
        manualRenderingMode = .realtime
        if let block = self.playingBlock {
            self.observePlayingTime(forInterval: self.interval, queue: self.observeQueue, block: block)
        }
    }
    
    public func export(size: CGSize? = nil, fileName: String? = nil, progressHandler: @escaping ProgressHandler, completionHandler: @escaping ((URL?, Error?) -> Void)) -> CancelClosure? {
        guard manualRenderingMode == .offline else {
            completionHandler(nil, NSError(domain: "", code: 2, userInfo: [NSLocalizedFailureReasonErrorKey:""]))
            return nil
        }
        let renderSize = self.videoClap.videoDescription.renderSize
        let renderScale = self.videoClap.videoDescription.renderScale
        let exportRenderSize = size ?? renderSize.scaling(renderScale)
        let time = self.videoClap.requestCallbackHandler.compositionTime
        
        let playItem = self.currentItem.unsafelyUnwrapped
        
        playItem.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        let cache = playItem.videoComposition
        let videoComposition = playItem.videoComposition?.mutableCopy() as? AVMutableVideoComposition
        videoComposition?.renderSize = exportRenderSize
        videoComposition?.renderScale = 1.0
        self.videoClap.videoDescription.renderSize = exportRenderSize
        self.videoClap.videoDescription.renderScale = 1.0
        
        playItem.videoComposition = videoComposition
        
        return videoClap.export(playerItem: playItem, fileName: fileName, progressHandler: progressHandler) { (url, error) in
            self.videoClap.videoDescription.renderSize = renderSize
            self.videoClap.videoDescription.renderScale = renderScale
            playItem.videoComposition = cache
            playItem.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { (_) in
                completionHandler(url, error)
            }
        }
    }
    
    public func estimateVideoDuration() -> CMTime {
        return (try? videoClap.playerItemForPlay().asset.duration) ?? .zero
    }
    
}
