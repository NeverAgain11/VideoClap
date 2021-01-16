//
//  VCLottieTrackDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/22.
//

import AVFoundation
import Lottie

public class VCLottieTrackDescription: VCImageTrackDescription {
    
    public var rect: VCRect {
        get {
            switch imageLayout {
            case .fit:
                return .zero
            case .fill:
                return .zero
            case .center(_):
                return .zero
            case .rect(let rect):
                return rect
            }
        }
        set {
            imageLayout = .rect(newValue)
        }
    }
    
    internal var animationView: AnimationView?
    
    internal let frame: CGRect = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
    
    internal let contentMode: UIView.ContentMode = .scaleAspectFit
    
    internal var animation: Animation?
    
    public override var mediaURL: URL? {
        didSet {
            if let path = mediaURL?.path {
                animation = Animation.filepath(path)
            } else {
                animation = nil
            }
            if animation == nil {
                self.animationView = nil
            }
            reloadViewFlag = true
        }
    }
    
    private var reloadViewFlag: Bool = true
    
    func animationFrame(animationPlayTime: CMTime, handler: @escaping (_ frame: CIImage?) -> Void) {
        DispatchQueue.main.async {
            if self.reloadViewFlag {
                self.reloadViewFlag = false
                if let animation = self.animation {
                    self.animationView = AnimationView()
                    self.animationView?.contentMode = self.contentMode
                    self.animationView?.animation = animation
                    self.animationView?.frame = self.frame
                    self.animationView?.setNeedsDisplay()
                }
            }
            guard let animationView = self.animationView, let animation = animationView.animation else {
                handler(nil)
                return
            }
            let progress = CGFloat(animationPlayTime.seconds.truncatingRemainder(dividingBy: animation.duration)).map(from: 0...CGFloat(animation.duration), to: 0...1)
            if progress.isNaN && progress.isInfinite {
                handler(nil)
                return
            }
            animationView.currentProgress = progress
            let bounds = animationView.layer.bounds
            let snapshotLayer = animationView.layer
            DispatchQueue.global().async {
                let renderer = VCGraphicsRenderer()
                renderer.rendererRect = bounds
                let image = renderer.ciImage { (cgcontext) in
                    snapshotLayer.render(in: cgcontext)
                }
                handler(image)
            }
        }
    }
    
    public override func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCLottieTrackDescription()
        copyObj.mediaURL         = mediaURL
        copyObj.id               = id
        copyObj.timeRange        = timeRange
        copyObj.isFit            = isFit
        copyObj.isFlipHorizontal = isFlipHorizontal
        copyObj.filterIntensity  = filterIntensity
        copyObj.lutImageURL      = lutImageURL
        copyObj.rotateRadian     = rotateRadian
        copyObj.cropedRect       = cropedRect
        copyObj.trajectory       = trajectory
        copyObj.canvasStyle      = canvasStyle
        copyObj.imageLayout      = imageLayout
        copyObj.indexPath        = indexPath
        copyObj.animation        = animation
        copyObj.animationView    = animationView
        return copyObj
    }
    
    public override func originImage(time: CMTime, renderSize: CGSize, renderScale: CGFloat, compensateTimeRange: CMTimeRange?) -> CIImage? {
        locker.object(forKey: #function).lock()
        defer {
            locker.object(forKey: #function).unlock()
        }
        let group = DispatchGroup()
        var originImage: CIImage?
        group.enter()
        animationFrame(animationPlayTime: time) { (image) in
            originImage = image
            group.leave()
        }
        group.wait()
        return originImage
    }
    
}
