//
//  VCLottieToGIF.swift
//  VideoClap
//
//  Created by lai001 on 2021/3/10.
//

import Foundation
import Lottie
import Accelerate
import MobileCoreServices

public class VCLottieToGIF: NSObject {
    
    public func createGif(jsonURL: URL,
                          url: URL,
                          autoRemove: Bool = false,
                          sizeClosure: ((CGSize) -> CGSize)? = nil,
                          fpsClosure: ((Double) -> Double)? = nil,
                          progessCallback: @escaping (Double) -> Void,
                          closure: @escaping (_ error: Error?) -> Void) -> (() -> Void) {
        if FileManager.default.fileExists(atPath: jsonURL.path) == false {
            closure(NSError(domain: "", code: 0, userInfo: [:]))
            return { }
        }
        if FileManager.default.fileExists(atPath: url.path) {
            if autoRemove {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch let error {
                    closure(error)
                }
            } else {
                closure(NSError(domain: "", code: 1, userInfo: [:]))
                return { }
            }
        }
        guard let animation = Animation.filepath(jsonURL.path) else {
            closure(NSError(domain: "", code: 2, userInfo: [:]))
            return { }
        }
        
        let size = sizeClosure?(animation.size) ?? animation.size
        let fps = fpsClosure?(animation.framerate) ?? animation.framerate
        
        let animationView = AnimationView()
        animationView.contentMode = .scaleAspectFit
        animationView.animation = animation
        animationView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        animationView.setNeedsDisplay()
        
        if fps <= 0 || animationView.frame.width <= 0 || animationView.frame.height <= 0 {
            closure(NSError(domain: "", code: 3, userInfo: [:]))
            return { }
        }
        
        if animation.duration <= 0 {
            closure(NSError(domain: "", code: 4, userInfo: [:]))
            return { }
        }
        
        var isCancel: Bool = false
        
        DispatchQueue.global().async {
            let inter: TimeInterval = 1.0 / fps
            let group = DispatchGroup()
            let count = Int(animation.duration / inter)
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeGIF, count, nil) else {
                closure(NSError(domain: "", code: 5, userInfo: [:]))
                return
            }
            let fileProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]]
            let gifProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: inter]]
            CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
            for index in 0..<count {
                if isCancel {
                    CGImageDestinationFinalize(destination)
                    closure(NSError(domain: "", code: 6, userInfo: [:]))
                    return
                }
                let time = TimeInterval(index) * inter
                group.enter()
                self.animationFrame(animationView: animationView, animationPlayTime: time) { (image) in
                    if let _image = image {
                        CGImageDestinationAddImage(destination, _image, gifProperties as CFDictionary?)
                    }
                    progessCallback(Double(index + 1) / Double(count))
                    group.leave()
                }
                group.wait()
            }
            CGImageDestinationFinalize(destination)
            closure(nil)
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
