//
//  VCLottieToGIF.swift
//  VideoClap
//
//  Created by lai001 on 2021/3/10.
//

import Foundation
import Lottie
import MobileCoreServices

public class VCLottieToGIF: NSObject {
    
    public func createGif(jsonURL: URL,
                          url: URL,
                          autoRemove: Bool = false,
                          sizeClosure: ((CGSize) -> CGSize)? = nil,
                          fpsClosure: ((Double) -> Double)? = nil,
                          progessCallback: @escaping (Double) -> Void,
                          closure: @escaping (_ error: Error?) -> Void) -> (() -> Void)? {
        guard let animation = Animation.filepath(jsonURL.path), animation.duration > 0 else {
            closure(NSError(domain: "VCLottieToGIF", code: 1, userInfo: [NSLocalizedFailureReasonErrorKey:"Animation not available"]))
            return nil
        }
        
        let size = sizeClosure?(animation.size) ?? animation.size
        let fps = fpsClosure?(animation.framerate) ?? animation.framerate
        
        if fps <= 0 || size.width <= 0 || size.height <= 0 {
            closure(NSError(domain: "VCLottieToGIF", code: 2, userInfo: [NSLocalizedFailureReasonErrorKey:"Property not available"]))
            return nil
        }
        
        let animationView = AnimationView()
        animationView.contentMode = .scaleAspectFit
        animationView.animation = animation
        animationView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        animationView.setNeedsDisplay()
        
        let maker = VCGIFMaker()
        maker.autoRemove = autoRemove
        maker.fileProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]]
        maker.url = url
        maker.count = Int(animation.duration * fps)
        
        var isCancel: Bool = false
        DispatchQueue.global().async {
            let group = DispatchGroup()
            let inter = 1.0 / fps
            let imageProperties: [CFString : Any] = [kCGImagePropertyGIFDelayTime: inter,
                                                     kCGImagePropertyGIFUnclampedDelayTime: inter]
            maker.start { (index: Int) -> VCGIFFeedInfo in
                group.enter()
                var cgImage: CGImage?
                let time = TimeInterval(index) * inter
                self.animationFrame(animationView: animationView, animationPlayTime: time) { (image) in
                    cgImage = image
                    group.leave()
                }
                group.wait()
                progessCallback(Double(index + 1) / Double(maker.count))
                return VCGIFFeedInfo(cgImage: cgImage, imageProperties: imageProperties, isCancel: isCancel)
            } closure: { (error: Error?) in
                closure(error)
            }
        }
        return {
            isCancel = true
        }
    }
    
    func animationFrame(animationView: AnimationView, animationPlayTime: TimeInterval, handler: @escaping (_ frame: CGImage?) -> Void) {
        if animationView.animation == nil {
            handler(nil)
            return
        }
        DispatchQueue.main.async {
            animationView.currentTime = animationPlayTime
            let bounds = animationView.layer.bounds
            let snapshotLayer = animationView.layer
            snapshotLayer.setNeedsDisplay()
            DispatchQueue.main.async {
                DispatchQueue.global().async {
                    let renderer = VCGraphicsRenderer()
                    renderer.rendererRect = bounds
                    let image = renderer.cgImage { (cgcontext) in
                        snapshotLayer.render(in: cgcontext)
                    }
                    handler(image)
                }
            }
        }
    }
    
}
