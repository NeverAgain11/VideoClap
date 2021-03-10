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
                          size: CGSize = CGSize(width: 100, height: 100),
                          fps: TimeInterval = 24.0,
                          progessCallback: @escaping (Double) -> Void,
                          clocure: @escaping (_ error: Error?) -> Void) {
        if FileManager.default.fileExists(atPath: jsonURL.path) == false {
            return clocure(NSError(domain: "", code: 0, userInfo: [:]))
        }
        if fps <= 0 || size.width <= 0 || size.height <= 0 {
            return clocure(NSError(domain: "", code: 1, userInfo: [:]))
        }
        if FileManager.default.fileExists(atPath: url.path) {
            if autoRemove {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch let error {
                    clocure(error)
                }
            } else {
                return clocure(NSError(domain: "", code: 2, userInfo: [:]))
            }
        }
        guard let animation = Animation.filepath(jsonURL.path) else { return clocure(NSError(domain: "", code: 3, userInfo: [:])) }
        if animation.duration <= 0 {
            return clocure(NSError(domain: "", code: 4, userInfo: [:]))
        }
        let animationView = AnimationView()
        animationView.contentMode = .scaleAspectFit
        animationView.animation = animation
        animationView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        animationView.setNeedsDisplay()
        DispatchQueue.global().async {
            let inter: TimeInterval = 1.0 / fps
            let group = DispatchGroup()
            let count = Int(animation.duration / inter)
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeGIF, count, nil) else {
                return clocure(NSError(domain: "", code: 5, userInfo: [:]))
            }
            let fileProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]]
            let gifProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: inter]]
            CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
            for index in 0..<count {
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
            clocure(nil)
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
