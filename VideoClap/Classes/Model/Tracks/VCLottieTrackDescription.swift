//
//  VCLottieTrackDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/22.
//

import AVFoundation
import Lottie

public class VCLottieTrackDescription: NSObject, VCTrackDescriptionProtocol {
    
    public var id: String = ""
    
    public var timeRange: CMTimeRange = .zero
    
    public var rect: VCRect = VCRect(normalizeCenter: CGPoint(x: 0.5, y: 0.5), normalizeSize: CGSize(width: 0.5, height: 0.5))
    
    /// 顺时针，弧度制，1.57顺时针旋转90度，3.14顺时针旋转180度
    public var rotateRadian: Float = 0.0
    
    public var animationPlayTime: CMTime = .zero
    
    internal var animationView: AnimationView?
    
    public func setAnimationView(_ name: String, subdirectory: String) {
        let animation = Animation.named(name, subdirectory: subdirectory)
        animationView = AnimationView()
        animationView?.contentMode = .scaleAspectFit
        animationView?.animation = animation
        animationView?.frame = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
    }
    
    func animationFrame(handler: @escaping (_ frame: CIImage?) -> Void) {
        DispatchQueue.main.async {
            guard let animationView = self.animationView, let animation = animationView.animation else {
                handler(nil)
                return
            }
            let progress = CGFloat(self.animationPlayTime.seconds.truncatingRemainder(dividingBy: animation.duration)).map(from: 0...CGFloat(animation.duration), to: 0...1)
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
    
    public override init() {
        super.init()
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCLottieTrackDescription()
        copyObj.id                = id
        copyObj.rect              = rect
        copyObj.rotateRadian      = rotateRadian
        copyObj.timeRange         = timeRange
        copyObj.animationPlayTime = animationPlayTime
        
        if let animationView = animationView {
            let copyAnimationView = AnimationView()
            copyAnimationView.contentMode = animationView.contentMode
            copyAnimationView.animation   = animationView.animation
            copyAnimationView.frame       = animationView.frame
            copyObj.animationView         = copyAnimationView
        }
        return copyObj
    }
    
}
