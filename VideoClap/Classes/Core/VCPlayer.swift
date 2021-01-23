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
    
    public private(set) lazy var videoClap: VideoClap = {
        let videoClap = VideoClap()
        videoClap.requestCallbackHandler.renderTarget = self
        return videoClap
    }()
    
    public lazy var containerView: VCPlayerContainerView = {
        let view = VCPlayerContainerView(player: self)
        return view
    }()
    
    private var stopRenderFlag: Bool = false
    
    private var playingBlock: ((_ time: CMTime) -> Void)?
    
    private var interval: CMTime = .init(seconds: 1/30)
    
    private var observeQueue: DispatchQueue = .main
    
    public private(set) var manualRenderingMode: VCManualRenderingMode = .realtime
    
    private var images: [String : CIImage] = [:]
    
    private var cacheAttributes: [UICollectionViewLayoutAttributes] = []
    
    public override init() {
        super.init()
    }
    
    public func contextChanged() {
        guard containerView.superview != nil else {
            return
        }
    }
    
    public func draw(images: [String : CIImage], blackImage: CIImage) -> CIImage? {
        if stopRenderFlag {
            return nil
        }
//        self.images = images
//        self.cacheAttributes = []
//        let group = DispatchGroup()
//        for (index, image) in images.enumerated() {
//            let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: 0))
//            group.enter()
//            DispatchQueue.main.async {
//                attributes.frame = self.containerView.collectionView.bounds
//                group.leave()
//            }
//            group.wait()
//            self.cacheAttributes.append(attributes)
//        }
//
//        group.enter()
//        DispatchQueue.main.async {
//            self.containerView.reloadDataWithoutAnimation()
//            group.leave()
//        }
//        group.wait()
//        return nil
        
        var finalFrame: CIImage?
        
        finalFrame = images.sorted { (lhs, rhs) -> Bool in
            return lhs.value.indexPath > rhs.value.indexPath
        }.reduce(finalFrame) { (result, args: (key: String, value: CIImage)) -> CIImage? in
            return result?.composited(over: args.value) ?? args.value
        }
        
        finalFrame = finalFrame?.composited(over: blackImage) ?? blackImage // 让背景变为黑色，防止出现图像重叠

        if let ciImage = finalFrame {
            let cgImage = CIContext.share.createCGImage(ciImage, from: CGRect(origin: .zero, size: videoClap.videoDescription.renderSize.scaling(videoClap.videoDescription.renderScale)))
            DispatchQueue.main.async {
                self.containerView.renderView.layer.contents = cgImage
//                self.containerView.reloadDataWithoutAnimation()
            }
        } else {
            DispatchQueue.main.async {
                self.containerView.renderView.layer.contents = nil
//                self.containerView.reloadDataWithoutAnimation()
            }
        }
        return nil
    }
    
    /// 替换掉当前的item
    /// - Parameters:
    ///   - item: 新的player item，替换掉当前的item
    ///   - time: 要索引的时间，如果该参数nil，则会自动将新的player item索引到原来player item的时间，如果不为nil，新的player item会索引到该时间（范围在0到player item的时长）
    /// - Returns: 最终的索引的时间
    public func smoothReplaceCurrentItem(with item: AVPlayerItem?, time: CMTime? = nil) -> CMTime {
        guard let newPlayerItem = item else {
            super.replaceCurrentItem(with: item)
            return .zero
        }
        stopRenderFlag = true
        super.pause()
        self.removePlayingTimeObserver()
        var seekTime = time ?? videoClap.requestCallbackHandler.compositionTime
        seekTime = CMTimeClampToRange(seekTime, range: CMTimeRange(start: .zero, duration: newPlayerItem.duration))
        newPlayerItem.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
        self.replaceCurrentItem(with: newPlayerItem)
        self.stopRenderFlag = false
        if let block = self.playingBlock {
            self.observePlayingTime(forInterval: self.interval, queue: self.observeQueue, block: block)
        }
        return seekTime
    }
    
    /// 重新构建一个新的player item并替换掉当前的item
    /// - Returns: 构建失败或者替换掉当前的item失败，返回nil，否则返回player item的索引时间
    @discardableResult public func reload() -> CMTime? {
        do {
            let newPlayerItem = try self.videoClap.playerItemForPlay()
            contextChanged()
            return self.smoothReplaceCurrentItem(with: newPlayerItem)
        } catch let error {
            log.error(error)
        }
        return nil
    }
    
    /// 刷新当前帧，调用此方法会暂停视频的播放
    /// - Returns: 当暂停播放失败或者currentItem为nil的时候返回false，刷新当前帧失败
    @discardableResult public func reloadFrame() -> Bool {
        super.pause()
        if isPlaying {
            return false
        }
        guard let item = currentItem else { return false }
        contextChanged()
        let videoComposition = item.videoComposition?.mutableCopy() as? AVVideoComposition
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
            videoClap.requestCallbackHandler.renderTarget = VCOfflineRenderTarget()
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
    
}

extension VCPlayer: VCViewLayoutDelegate, UICollectionViewDataSource {
    
    public func layoutAttributes() -> [UICollectionViewLayoutAttributes]? {
        return cacheAttributes
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cacheAttributes.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VCPreviewCell", for: indexPath) as! VCPreviewCell
        let image = self.images.sorted { (lhs, rhs) -> Bool in
            return lhs.value.indexPath > rhs.value.indexPath
        }[indexPath.item].value
        cell.imageView.image = UIImage(ciImage: image)
        return cell
    }
    
}
