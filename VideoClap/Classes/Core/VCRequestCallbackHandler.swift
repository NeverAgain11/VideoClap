//
//  VCRequestCallbackHandler.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/22.
//

import Foundation
import AVFoundation
import GLKit
import Accelerate
import CoreAudio
import CoreAudioKit

open class VCRequestCallbackHandler: NSObject, VCRequestCallbackHandlerProtocol {
    
    private var lockerDic: [String : NSLock] = [:]
    
    private var locker: NSLock = NSLock()
    
    public var videoDescription: VCVideoDescription = VCVideoDescription()
    
    private var imageTrackEnumor: [String : VCImageTrackDescription] = [:]
    
    private var videoTrackEnumor: [String : VCVideoTrackDescription] = [:]
    
    private var lottieTrackEnumor: [String : VCLottieTrackDescription] = [:]
    
    private var laminationTrackEnumor: [String : VCLaminationTrackDescription] = [:]
    
    private var audioTrackEnumor: [String : VCAudioTrackDescription] = [:]
    
    private var preprocessFinishedImages: [String:CIImage] = [:] // 预处理完的图片
    
    public func contextChanged() {
        imageTrackEnumor = videoDescription.imageTracks.reduce([:]) { (result, imageTrack) -> [String : VCImageTrackDescription] in
            var mutable = result
            mutable[imageTrack.id] = imageTrack
            return mutable
        }
        
        videoTrackEnumor = videoDescription.videoTracks.reduce([:]) { (result, imageTrack) -> [String : VCVideoTrackDescription] in
            var mutable = result
            mutable[imageTrack.id] = imageTrack
            return mutable
        }
        
        lottieTrackEnumor = videoDescription.lottieTracks.reduce([:]) { (result, imageTrack) -> [String : VCLottieTrackDescription] in
            var mutable = result
            mutable[imageTrack.id] = imageTrack
            return mutable
        }
        
        laminationTrackEnumor = videoDescription.laminationTracks.reduce([:]) { (result, imageTrack) -> [String : VCLaminationTrackDescription] in
            var mutable = result
            mutable[imageTrack.id] = imageTrack
            return mutable
        }
        
        audioTrackEnumor = videoDescription.audioTracks.reduce([:]) { (result, imageTrack) -> [String : VCAudioTrackDescription] in
            var mutable = result
            mutable[imageTrack.id] = imageTrack
            return mutable
        }
    }
    
    func preprocess(image: CIImage, trackID: String) {
        guard let mediaTrack = imageTrackEnumor[trackID] ?? videoTrackEnumor[trackID] else { return }
        let renderSize = videoDescription.renderSize
        var frame = image
        let id = mediaTrack.id
        let isFit = mediaTrack.isFit
        let isFilp = mediaTrack.isFlipHorizontal
        let optionalPrefferdTransform: CGAffineTransform? = mediaTrack.prefferdTransform

        var transform = CGAffineTransform.identity
        do {
            frame = correctingTransform(image: frame, prefferdTransform: optionalPrefferdTransform)

            if var cropRect = mediaTrack.cropedRect {
                let nw = cropRect.width
                let nh = cropRect.height
                let no = cropRect.origin

                if nw == 1.0 && nh == 1.0 && no == CGPoint(x: 0, y: 0) {
                    // 裁剪区域为原图大小区域，不做处理
                } else {
                    let width = frame.extent.width
                    let height = frame.extent.height

                    cropRect.size = CGSize(width: width * nw, height: height * nh)
                    cropRect.origin = CGPoint(x: width * no.x, y: height * no.y)
                    cropRect.origin.y = frame.extent.height - cropRect.origin.y - cropRect.height

                    frame = frame.cropped(to: cropRect)
                }
            }

            let moveFrameCenterToRenderRectOrigin = CGAffineTransform(translationX: -frame.extent.midX, y: -frame.extent.midY)
            transform = transform.concatenating(moveFrameCenterToRenderRectOrigin)
            defer {
                let moveFrameCenterToRenderRectCenter = CGAffineTransform(translationX: renderSize.width / 2.0, y: renderSize.height / 2.0)
                transform = transform.concatenating(moveFrameCenterToRenderRectCenter)
            }

            let extent = frame.extent
            let widthRatio = renderSize.width /  extent.width
            let heightRatio = renderSize.height / extent.height
            let ratio: CGFloat = isFit ? min(widthRatio, heightRatio): max(widthRatio, heightRatio)
            let scaleTransform = CGAffineTransform(scaleX: ratio, y: ratio)
            transform = transform.concatenating(scaleTransform)

            if mediaTrack.rotateRadian.isZero == false {
                let angle = -mediaTrack.rotateRadian // 转为负数，变成顺时针旋转
                let rotationTransform = CGAffineTransform(rotationAngle: angle)
                transform = transform.concatenating(rotationTransform)
            }

            if isFilp {
                let scale = CGAffineTransform(scaleX: -1, y: 1)
                transform = transform.concatenating(scale)
            }
        }

        if #available(iOS 10.0, *) {
            frame = frame.transformed(by: transform, highQualityDownsample: true)
        } else {
            frame = frame.transformed(by: transform)
        }
        
        if let lutImageURL = mediaTrack.lutImageURL, let filterLutImage = lutImage(url: lutImageURL), mediaTrack.filterIntensity.floatValue > 0.0 {  // 查找表，添加滤镜
            let lutFilter = VCLutFilter()
            lutFilter.inputIntensity = mediaTrack.filterIntensity
            lutFilter.inputImage = frame
            lutFilter.lookupImage = filterLutImage
            if let outputImage = lutFilter.outputImage {
                frame = outputImage
            }
        }
        
        preprocessFinishedImages[id] = frame
        
    }
    
    /// 预处理图片或者视频帧 ，自适应或者铺满，水平翻转，添加滤镜
    private func preprocess(item: VCRequestItem, compositionTime: CMTime) {
        var hasBeenProcessSourceFrames: [String] = []
        for (trackID, sourceFrame) in item.sourceFrameDic {
            hasBeenProcessSourceFrames.append(trackID)
            preprocess(image: sourceFrame, trackID: trackID)
        }
        
        for videoTrack in item.videoTracks {
            if hasBeenProcessSourceFrames.contains(videoTrack.id) == false, let frame = trackFrame(trackID: videoTrack.id) {
                preprocess(image: frame, trackID: videoTrack.id)
            }
        }
        
        for imageTrack in item.imageTracks {
            if let image = trackImage(trackID: imageTrack.id) {
                preprocess(image: image, trackID: imageTrack.id)
            }
        }
    }
    
    func processTransions(item: VCRequestItem, compositionTime: CMTime, blackImage: CIImage) -> CIImage? {
        let transitionImageIDs = Set(item.transitions.flatMap({ [$0.transition.fromId, $0.transition.toId] }))
        let excludeTransitionImages = transitionImageIDs.symmetricDifference(preprocessFinishedImages.map({ $0.key }))  // 没有过渡的图片ID集合
        var excludeTransitionImage: CIImage? // 没有过渡的图片合成一张图片
        var optionalTransitionImage: CIImage? // 过渡的图片合成一张图片
        
        let renderSize = videoDescription.renderSize
        for transition in item.transitions {
            let progress = (compositionTime.seconds - transition.timeRange.start.seconds) / transition.timeRange.duration.seconds
            guard progress.isInfinite == false, progress.isNaN == false else {
                continue
            }
            if let fromImage = preprocessFinishedImages[transition.transition.fromId], let toImage = preprocessFinishedImages[transition.transition.toId] {
                if let image = transition.transition.transition(renderSize: renderSize,
                                                                progress: Float(progress),
                                                                fromImage: fromImage.composited(over: blackImage),
                                                                toImage: toImage.composited(over: blackImage)) {
                    if let transitionImage = optionalTransitionImage {
                        optionalTransitionImage = transitionImage.composited(over: image)
                    } else {
                        optionalTransitionImage = image
                    }
                }
            }
        }
        
        excludeTransitionImage = preprocessFinishedImages
            .filter({ excludeTransitionImages.contains($0.key) })
            .reduce(excludeTransitionImage) { (result, args: (key: String, value: CIImage)) -> CIImage? in
                return result?.composited(over: args.value) ?? args.value
            }
        
        if let excludeTransitionImage = excludeTransitionImage {
            optionalTransitionImage = optionalTransitionImage?.composited(over: excludeTransitionImage)
        }
        
        return optionalTransitionImage
    }
    
    func processTrajectories(item: VCRequestItem, compositionTime: CMTime) {
        let renderSize = videoDescription.renderSize
        for trajectory in item.trajectories {
            let progress = (compositionTime.seconds - trajectory.timeRange.start.seconds) / trajectory.timeRange.duration.seconds
            guard progress.isInfinite == false, progress.isNaN == false else {
                continue
            }
            
            if let image = preprocessFinishedImages[trajectory.id] {
                if let processImage = trajectory.transition(renderSize: renderSize, progress: CGFloat(progress), image: image) {
                    preprocessFinishedImages[trajectory.id] = processImage
                }
            }
        }
    }
    
    func processLamination(item: VCRequestItem, compositionTime: CMTime) -> CIImage? {
        var optionalLaminationImage: CIImage? // 所有叠层合成一张图片
        let renderSize = videoDescription.renderSize
        for laminationTrack in item.laminationTracks {
            if let url = laminationTrack.mediaURL, var image = laminationImage(url: url) {
                let scaleX = renderSize.width / image.extent.width
                let scaleY = renderSize.height / image.extent.height
                image = image.transformed(by: .init(scaleX: scaleX, y: scaleY))
                if let laminationImage = optionalLaminationImage {
                    optionalLaminationImage = laminationImage.composited(over: image)
                } else {
                    optionalLaminationImage = image
                }
            }
        }
        return optionalLaminationImage
    }
    
    func processLottie(item: VCRequestItem, compositionTime: CMTime) -> CIImage? {
        let renderSize = videoDescription.renderSize
        
        let animationStickers = item.lottieTracks
        var compositionSticker: CIImage?
        let group = DispatchGroup()
        for animationSticker in animationStickers {
            group.enter()
            animationSticker.animationPlayTime = compositionTime - animationSticker.timeRange.start
            animationSticker.animationFrame { (image: CIImage?) in
                var stickerImage: CIImage?
                if let image = image {
                    let width = renderSize.width * animationSticker.rect.normalizeWidth // 贴纸宽度，基于像素
                    let height = renderSize.height * animationSticker.rect.normalizeHeight // 贴纸高度，基于像素
                    let left = animationSticker.rect.normalizeCenter.x * renderSize.width // 贴纸中心距离画布左边的距离，基于像素
                    let bottom = animationSticker.rect.normalizeCenter.y * renderSize.height // 贴纸中心距离画布底部的距离，基于像素

                    let scaleX = width / image.extent.size.width
                    let scaleY = height / image.extent.size.height
                    var transform: CGAffineTransform = .identity
                    let move1 = CGAffineTransform(translationX: -image.extent.size.width / 2.0, // 将贴纸中心移动到画布左下角
                                                  y: -image.extent.size.height / 2.0)
                    let rotate = CGAffineTransform(rotationAngle: CGFloat(-animationSticker.rotateRadian))
                    let scale = CGAffineTransform(scaleX: scaleX, y: scaleY)
                    let move2 = CGAffineTransform(translationX: left, y: bottom)
                    transform = transform.concatenating(move1).concatenating(rotate).concatenating(scale).concatenating(move2)

                    stickerImage = image.transformed(by: transform)
                }
                if let sticker = compositionSticker, let stickerImage = stickerImage {
                    compositionSticker = stickerImage.composited(over: sticker)
                } else if let stickerImage = stickerImage {
                    compositionSticker = stickerImage
                }
                group.leave()
            }
            group.wait()
        }
        
        return compositionSticker
    }
    
    func processWaterMark() -> CIImage? {
        let renderSize = videoDescription.renderSize
        if let url = videoDescription.waterMarkImageURL, var waterMarkImage = watermarkImage(url: url), let waterMarkRect = videoDescription.waterMarkRect {
            let width = renderSize.width * waterMarkRect.normalizeWidth // 水印宽度，基于像素
            let height = renderSize.height * waterMarkRect.normalizeHeight // 水印高度，基于像素
            let left = waterMarkRect.normalizeCenter.x * renderSize.width // 水印中心距离画布左边的距离，基于像素
            let bottom = waterMarkRect.normalizeCenter.y * renderSize.height // 水印中心距离画布底部的距离，基于像素

            let scaleX = width / waterMarkImage.extent.size.width
            let scaleY = height / waterMarkImage.extent.size.height
            var transform: CGAffineTransform = .identity
            let move1 = CGAffineTransform(translationX: -waterMarkImage.extent.size.width / 2.0, // 将水印中心移动到画布左下角
                                          y: -waterMarkImage.extent.size.height / 2.0)
            let scale = CGAffineTransform(scaleX: scaleX, y: scaleY)
            let move2 = CGAffineTransform(translationX: left, y: bottom)
            transform = transform.concatenating(move1).concatenating(scale).concatenating(move2)

            waterMarkImage = waterMarkImage.transformed(by: transform)
            return waterMarkImage
        }
        return nil
    }
    
    open func handle(item: VCRequestItem, compositionTime: CMTime, blackImage: CIImage, finish: (CIImage?) -> Void) {
        preprocessFinishedImages.removeAll()
        var finalFrame: CIImage?
        
        preprocess(item: item, compositionTime: compositionTime)
        
        processTrajectories(item: item, compositionTime: compositionTime)
        
        let transionImage = processTransions(item: item, compositionTime: compositionTime, blackImage: blackImage)
        let laminationImage = processLamination(item: item, compositionTime: compositionTime)
        let lottieImage = processLottie(item: item, compositionTime: compositionTime)
        
        if let transionImage = transionImage {
            finalFrame = transionImage
        } else {
            finalFrame = preprocessFinishedImages.reduce(finalFrame) { (result, args: (key: String, value: CIImage)) -> CIImage? in
                return result?.composited(over: args.value) ?? args.value
            }
        }
        
        if let frame = finalFrame, let lottieImage = lottieImage {
            finalFrame = lottieImage.composited(over: frame)
        } else if let lottieImage = lottieImage {
            finalFrame = lottieImage
        }
        
        if let frame = finalFrame, let laminationImage = laminationImage {
            finalFrame = laminationImage.composited(over: frame)
        } else if let laminationImage = laminationImage {
            finalFrame = laminationImage
        }
        
        if let waterMark = processWaterMark() {
            let backgroundImage = finalFrame ?? blackImage
            finalFrame = waterMark.composited(over: backgroundImage)
        }
        
        finalFrame = finalFrame?.composited(over: blackImage) ?? blackImage // 让背景变为黑色，防止出现图像重叠
        finish(finalFrame)
    }
    
    public func handle(trackID: String,
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
        
        guard let audioTrack = audioTrackEnumor[trackID], let url = audioTrack.mediaURL else { return }

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

    // 校正视频方向
    public func correctingTransform(image: CIImage, prefferdTransform optionalPrefferdTransform: CGAffineTransform?) -> CIImage {
        if var prefferdTransform = optionalPrefferdTransform {
            let extent = image.extent
            let transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: extent.origin.y * 2 + extent.height)
            prefferdTransform = transform.concatenating(prefferdTransform).concatenating(transform)
            return image.transformed(by: prefferdTransform)
        } else {
            return image
        }
    }
    
    private func lutImage(url: URL) -> CIImage? {
        return image(url: url)
    }
    
    private func laminationImage(url: URL) -> CIImage? {
        return image(url: url)
    }
    
    private func watermarkImage(url: URL) -> CIImage? {
        return image(url: url)
    }
    
    private func image(url: URL) -> CIImage? {
        if let cacheImage = VCImageCache.share.image(forKey: url.path) {
            return cacheImage
        } else {
            let image = CIImage(contentsOf: url)
            VCImageCache.share.storeImage(toMemory: image, forKey: url.path)
            return image
        }
    }
    
    public func trackImage(trackID: String) -> CIImage? {
        let locker = self.locker(forKey: #function)
        locker.lock()
        defer {
            locker.unlock()
        }
        
        if let imageTrack = imageTrackEnumor[trackID] {
            if let url = imageTrack.mediaURL {
                return image(url: url)
            }
        }
        return nil
    }
    
    public func trackFrame(trackID: String) -> CIImage? {
        let locker = self.locker(forKey: #function)
        locker.lock()
        defer {
            locker.unlock()
        }
        if let videoTrack = videoTrackEnumor[trackID] {
            
            let storeKey = trackID + "video_first_frame"
            if let cacheImage = VCImageCache.share.image(forKey: storeKey) {
                return cacheImage
            } else if let videoUrl = videoTrack.mediaURL {
                var frame: CIImage?
                let asset = AVAsset(url: videoUrl)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                generator.requestedTimeToleranceAfter = .zero
                generator.requestedTimeToleranceBefore = .zero
                do {
                    let cgimage = try generator.copyCGImage(at: CMTime(seconds: 5.0), actualTime: nil)
                    let ciimage = CIImage(cgImage: cgimage)
                    VCImageCache.share.storeImage(toMemory: ciimage, forKey: storeKey)
                    frame = ciimage
                } catch {
                    frame = nil
                }
                return frame
            }
            
        }
        return nil
    }
    
    public func reloadFrame(player: AVPlayer) {
        guard player.rate == 0 else { return }
        guard let item = player.currentItem else { return }
        contextChanged()
        let videoComposition = item.videoComposition?.mutableCopy() as? AVVideoComposition
        item.videoComposition = videoComposition
    }
    
    private func locker(forKey key: String) -> NSLock {
        locker.lock()
        defer {
            locker.unlock()
        }
        if let locker = lockerDic[key] {
            return locker
        } else {
            let locker = NSLock()
            lockerDic[key] = locker
            return locker
        }
    }
    
}
