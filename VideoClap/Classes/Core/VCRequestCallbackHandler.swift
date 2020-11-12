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
    
    private lazy var ciContext: CIContext = {
        if let gpu = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: gpu)
        }
        if let eaglContext = EAGLContext(api: .openGLES3) ?? EAGLContext(api: .openGLES2) {
            return CIContext(eaglContext: eaglContext)
        }
        return CIContext()
    }()
    
    public var videoDescription: VCVideoDescriptionProtocol = VCFullVideoDescription()
    
    open func handle(items: [VCRequestItem], compositionTime: CMTime, blackImage: CIImage, finish: (CIImage?) -> Void) {
        var items = items
        var finalFrame: CIImage?
        defer {
            finalFrame = finalFrame?.composited(over: blackImage) // 让背景变为黑色，防止出现图像重叠
            finish(finalFrame)
        }
        guard let videoDescription = self.videoDescription as? VCFullVideoDescription else { return }
        let renderSize = videoDescription.renderSize
        guard let mediaTracks = videoDescription.mediaTracks as? [VCMediaTrack] else { return }

        let fastEnumor = VCFastEnumor<VCMediaTrack>.init(group: mediaTracks)
        
        var preprocessFinishedImages: [String:CIImage] = [:] // 预处理完的图片
        var findTransitions: [VCTransitionProtocol] = [] // 当前时间的所有过渡
        var transitionFinishImages: [CIImage] = [] // 执行完过渡的所有图片
        var transitionFinishImage: CIImage? // 执行完过渡的所有图片合成一张图片
        var excludeTransitionImages: [String] = [] // 没有过渡的图片ID集合
        var excludeTransitionImage: CIImage? // 没有过渡的图片合成一张图片
        
        var findTrajectories: [VCTrajectoryProtocol] = [] // 当前时间的所有轨迹
        
        for transition in videoDescription.transitions { // 搜寻在当前时间的所有过渡
            
            guard let fromTrack = fastEnumor.object(id: transition.fromId), let toTrack = fastEnumor.object(id: transition.toId) else { continue }
            let fromTimeRange = fromTrack.timeRange
            let toTimeRange = toTrack.timeRange
            
            if fromTimeRange.end == toTimeRange.start { // 两个轨道没有重叠，但是需要过渡动画，根据 'range' 计算出过渡时间，并判断当前是否需要过渡动画
                let start: CMTime = CMTime(seconds: fromTimeRange.end.seconds - fromTimeRange.duration.seconds * Double(transition.range.left))
                let end: CMTime = CMTime(seconds: toTimeRange.start.seconds + toTimeRange.duration.seconds * Double(transition.range.right))
                if CMTimeRange(start: start, end: end).containsTime(compositionTime) {
                    let ids = items.map({ $0.id })
                    if ids.contains(transition.toId) == false {
                        items.append(VCRequestItem(frame: transition.toTrackVideoTransitionFrame(), id: transition.toId))
                    }
                    if ids.contains(transition.fromId) == false {
                        items.append(VCRequestItem(frame: transition.fromTrackVideoTransitionFrame(), id: transition.fromId))
                    }
                    findTransitions.append(transition)
                }
            } else { // 两个轨道有重叠
                let ids = items.map({ $0.id })
                if ids.contains(transition.fromId) && ids.contains(transition.toId) {
                    findTransitions.append(transition)
                }
            }
        }
        
        for trajectory in videoDescription.trajectories { // 搜寻在当前时间的所有轨迹
            let ids = items.map({ $0.id })
            if ids.contains(trajectory.id), trajectory.timeRange.containsTime(compositionTime) {
                findTrajectories.append(trajectory)
            }
        }
        
        for item in items {
            let ids = findTransitions.flatMap({ [$0.fromId, $0.toId] })
            if ids.contains(item.id) == false {
                excludeTransitionImages.append(item.id)
            }
        }
        
        for item in items { // 对图片预处理，自适应或者铺满，水平翻转，添加滤镜
            guard let mediaTrack = fastEnumor.object(id: item.id) else { continue }
            guard var frame = item.frame else {
                continue
            }
            let id = item.id
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
            
            if let filterLutImage = mediaTrack.filterLutImageImage(), mediaTrack.filterIntensity.floatValue > 0.0 {  // 查找表，添加滤镜
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
        
        for trajectory in findTrajectories { // 应用轨迹
            if let preprocessFinishedImage = preprocessFinishedImages[trajectory.id] {
                let progress: CGFloat = CGFloat(compositionTime.value - trajectory.timeRange.start.value) / CGFloat(trajectory.timeRange.duration.value)
                if let image = trajectory.transition(renderSize: renderSize,
                                                     progress: progress,
                                                     image: preprocessFinishedImage) {
                    preprocessFinishedImages[trajectory.id] = image
                }
            }
        }
        
        for findTransition in findTransitions { // 对每个过渡应用过渡效果
            if let fromImage = preprocessFinishedImages[findTransition.fromId], let toImage = preprocessFinishedImages[findTransition.toId] {
                let fromTrack = fastEnumor.object(id: findTransition.fromId)!
                let toTrack = fastEnumor.object(id: findTransition.toId)!
                let fromTimeRange = fromTrack.timeRange
                let toTimeRange = toTrack.timeRange
                
                var start: CMTime = .zero
                var end: CMTime = .zero
                var duration: CMTime = .zero
                var progress: Float = 0.0
                
                if fromTimeRange.end == toTimeRange.start { // 两个轨道没有重叠的情况
                    start = CMTime(seconds: fromTimeRange.end.seconds - fromTimeRange.duration.seconds * Double(findTransition.range.left))
                    end = CMTime(seconds: toTimeRange.start.seconds + toTimeRange.duration.seconds * Double(findTransition.range.right))
                } else {  // 两个轨道重叠的情况，过渡开始时间取 'to' 轨道的开始时间，过渡结束时间取 'from' 轨道的结束时间
                    start = fastEnumor.object(id: findTransition.toId)!.timeRange.start
                    end = fastEnumor.object(id: findTransition.fromId)!.timeRange.end
                }
                duration = end - start
                progress = Float((compositionTime - start).seconds / duration.seconds)
                if progress.isNaN == false, progress.isInfinite == false, let image = findTransition.transition(renderSize: videoDescription.renderSize,
                                                                                                                progress: progress,
                                                                                                                fromImage: fromImage.composited(over: blackImage),
                                                                                                                toImage: toImage.composited(over: blackImage)) {
                    transitionFinishImages.append(image)
                }
            }
        }
        
        transitionFinishImage = transitionFinishImages.reduce(transitionFinishImage) { (result, image) -> CIImage? in // 所有过渡完成的图片合成一张图片
            if let result = result {
                return sourceAtopCompositing(inputImage: result, inputBackgroundImage: image)
            } else {
                return image
            }
        }
        
        excludeTransitionImage = excludeTransitionImages.reduce(excludeTransitionImage) { (result, imageID: String) -> CIImage? in
            if let inputImage = preprocessFinishedImages[imageID], let result = result {
                return sourceAtopCompositing(inputImage: inputImage, inputBackgroundImage: result)
            } else if let result = result {
                return result
            } else {
                return preprocessFinishedImages[imageID]
            }
        }
        
        if let backgroundImage = transitionFinishImage, let inputImage = excludeTransitionImage {
            finalFrame = sourceAtopCompositing(inputImage: inputImage, inputBackgroundImage: backgroundImage)
        } else if let excludeTransitionImage = excludeTransitionImage {
            finalFrame = excludeTransitionImage
        } else if let transitionFinishImage = transitionFinishImage {
            finalFrame = transitionFinishImage
        }
        
        var finalLaminationImage: CIImage? // 所有叠层合成一张图片
        let findLaminations = videoDescription.laminations.filter { (lamination: VCLamination) -> Bool in // // 当前时间的所有叠层
            return lamination.timeRange.containsTime(compositionTime)
        }

        for lamination in findLaminations {
            if let image = lamination.image() {
                if let laminationImage = finalLaminationImage {
                    finalLaminationImage = sourceAtopCompositing(inputImage: laminationImage, inputBackgroundImage: image)
                } else {
                    finalLaminationImage = image
                }
            }
        }
        
        do { // 贴纸动画
            let animationStickers = videoDescription.animationStickers.filter({ $0.timeRange.containsTime(compositionTime) })
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
            
            if let sticker = compositionSticker, let frame = finalFrame {
                finalFrame = sticker.composited(over: frame)
            }
        }
        
        if var laminationImage = finalLaminationImage, let backgroudImage = finalFrame { // 叠层
            let scaleX = renderSize.width / laminationImage.extent.width
            let scaleY = renderSize.height / laminationImage.extent.height
            laminationImage = laminationImage.transformed(by: .init(scaleX: scaleX, y: scaleY))
            finalFrame = laminationImage.composited(over: backgroudImage)
        }
        
        if var waterMarkImage = videoDescription.waterMarkImage(), let waterMarkRect = videoDescription.waterMarkRect, let backgroudImage = finalFrame {
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
            finalFrame = waterMarkImage.composited(over: backgroudImage)
        }

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
        
        guard let videoDescription = self.videoDescription as? VCFullVideoDescription else { return }
        guard let mediaTracks = videoDescription.mediaTracks as? [VCMediaTrack] else { return }
        let fastEnumor = VCFastEnumor<VCMediaTrack>.init(group: mediaTracks)
        
        guard let audioTrack = fastEnumor.object(id: trackID), let url = audioTrack.mediaURL else { return }
        
        if #available(iOS 11.0, *) {
            do {
                let audioFile = try AVAudioFile(forReading: url)
                let pcmFormat = audioFile.processingFormat
                audioTrack.audioEffectProvider?.handle(timeRange: timeRange,
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
    
}

extension VCRequestCallbackHandler {
    
    func cropBusinessCardForPoints(image: CIImage, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
        
        var businessCard: CIImage
        businessCard = image.applyingFilter("CIPerspectiveTransformWithExtent",
                                            parameters: [
                                                "inputExtent": CIVector(cgRect: image.extent),
                                                "inputTopLeft": CIVector(cgPoint: topLeft),
                                                "inputTopRight": CIVector(cgPoint: topRight),
                                                "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                                                "inputBottomRight": CIVector(cgPoint: bottomRight)
                                            ])
        businessCard = image.cropped(to: businessCard.extent)
        
        return businessCard
    }
    
    func sourceOverCompositing(inputImage: CIImage, inputBackgroundImage: CIImage) -> CIImage? {
        let filter = CIFilter(name: "CISourceOverCompositing")!
        filter.setValue(inputImage, forKey: "inputImage")
        filter.setValue(inputBackgroundImage, forKey: "inputBackgroundImage")
        return filter.outputImage
    }
    
    func twirlDistortionCompositing(radius: CGFloat, inputImage: CIImage) -> CIImage? {
        let twirlFilter = CIFilter(name: "CITwirlDistortion")!
        twirlFilter.setValue(inputImage, forKey: kCIInputImageKey)
        twirlFilter.setValue(radius, forKey: kCIInputRadiusKey)
        let x = inputImage.extent.midX
        let y = inputImage.extent.midY
        twirlFilter.setValue(CIVector(x: x, y: y), forKey: kCIInputCenterKey)
        return twirlFilter.outputImage
    }
    
    func maximumCompositing(inputImage: CIImage, inputBackgroundImage: CIImage) -> CIImage? {
        let combineFilter = CIFilter(name: "CIMaximumCompositing")!
        combineFilter.setValue(inputImage, forKey: kCIInputImageKey)
        combineFilter.setValue(inputBackgroundImage, forKey: kCIInputBackgroundImageKey)
        return combineFilter.outputImage
    }
    
    func sourceAtopCompositing(inputImage: CIImage, inputBackgroundImage: CIImage) -> CIImage? {
        let combineFilter = CIFilter(name: "CISourceAtopCompositing")!
        combineFilter.setValue(inputImage, forKey: kCIInputImageKey)
        combineFilter.setValue(inputBackgroundImage, forKey: kCIInputBackgroundImageKey)
        return combineFilter.outputImage
    }
    
    func minimumCompositing(inputImage: CIImage, inputBackgroundImage: CIImage) -> CIImage? {
        let combineFilter = CIFilter(name: "CIMinimumCompositing")!
        combineFilter.setValue(inputImage, forKey: kCIInputImageKey)
        combineFilter.setValue(inputBackgroundImage, forKey: kCIInputBackgroundImageKey)
        return combineFilter.outputImage
    }
    
    func affineTransformCompositing(inputImage: CIImage, cgAffineTransform: CGAffineTransform) -> CIImage? {
        let filter = CIFilter(name: "CIAffineTransform")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(NSValue(cgAffineTransform: cgAffineTransform), forKey: kCIInputTransformKey)
        return filter.outputImage
    }
    
    func lanczosScaleTransformCompositing(inputImage: CIImage, scale: Float, aspectRatio: Float) -> CIImage? {
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        filter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
        return filter.outputImage
    }
    
    func alphaCompositing(alphaValue: CGFloat, inputImage: CIImage) -> CIImage? {
        guard let overlayFilter: CIFilter = CIFilter(name: "CIColorMatrix") else { return nil }
        let overlayRgba: [CGFloat] = [0, 0, 0, alphaValue]
        let alphaVector: CIVector = CIVector(values: overlayRgba, count: 4)
        overlayFilter.setValue(inputImage, forKey: kCIInputImageKey)
        overlayFilter.setValue(alphaVector, forKey: "inputAVector")
        return overlayFilter.outputImage
    }
    
}
