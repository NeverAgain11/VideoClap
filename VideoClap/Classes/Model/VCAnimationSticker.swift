//
//  VCAnimationSticker.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/9.
//

import AVFoundation
import Lottie

public class VCAnimationSticker: NSObject, NSCopying, NSMutableCopying {
    
    public var id: String = ""
    
    public var rect: VCRect = VCRect(normalizeCenter: CGPoint(x: 0.5, y: 0.5), normalizeSize: CGSize(width: 0.5, height: 0.5))
    
    /// 顺时针，弧度制，1.57顺时针旋转90度，3.14顺时针旋转180度
    public var rotateRadian: Float = 0.0
    
    public var timeRange: CMTimeRange = .zero
    
    public var animationPlayTime: CMTime = .zero
    
    public var animationView: AnimationView?
    
    public func setAnimationView(_ name: String, subdirectory: String) {
        let animation = Animation.named(name, subdirectory: subdirectory)
        animationView = AnimationView()
        animationView?.contentMode = .scaleAspectFit
        animationView?.animation = animation
    }
    
    func animationFrame(handler: @escaping (_ frame: CIImage?) -> Void) {
        DispatchQueue.main.async {
            guard let animationView = self.animationView, let animation = animationView.animation else {
                handler(nil)
                return
            }
            animationView.currentProgress = CGFloat(self.animationPlayTime.seconds.truncatingRemainder(dividingBy: animation.duration)).map(from: 0...CGFloat(animation.duration), to: 0...1)
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
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCAnimationSticker()
        copyObj.id = id
        copyObj.rect = rect
        copyObj.rotateRadian = rotateRadian
        copyObj.timeRange = timeRange
        copyObj.animationPlayTime = animationPlayTime
        
        copyObj.animationView = AnimationView()
        copyObj.animationView?.contentMode = self.animationView?.contentMode ?? .scaleAspectFit
        copyObj.animationView?.animation = self.animationView?.animation
        return copyObj
    }
    
}
