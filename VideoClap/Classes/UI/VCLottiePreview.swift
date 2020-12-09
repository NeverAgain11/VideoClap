//
//  VCLottiePreview.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/21.
//

import Foundation
import AVFoundation
import SwiftyBeaver
import Lottie
import SnapKit
import SwiftyTimer
import simd

fileprivate var key = "_persistentInfo"

extension UIGestureRecognizer {
    
    var persistentInfo: Any? {
        get {
            objc_getAssociatedObject(self, &key)
        }
        set {
            objc_setAssociatedObject(self, &key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
}

extension CGRect {
    
    var center: CGPoint {
        get {
            return CGPoint(x: midX, y: midY)
        }
        
        set {
            self.origin = CGPoint(x: newValue.x - width / 2.0, y: newValue.y - height / 2.0)
        }
    }
    
}

public class VCLottiePreview: UIView {

    public var animationView: AnimationView?

    lazy var panGR: UIPanGestureRecognizer = {
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(panGRHandler(_:)))
        return panGR
    }()
    
    var lottieTrack: VCLottieTrackDescription?
    
//    var renderSize: CGSize = .zero
    
    public func setup(lottieTrack: VCLottieTrackDescription, renderSize: CGSize) {
        self.lottieTrack = lottieTrack
        if let animationView = lottieTrack.animationView {
            addGestureRecognizer(panGR)
//            self.backgroundColor = .red
            self.animationView?.removeFromSuperview()
            self.animationView = animationView
//            animationView.respectAnimationFrameRate = true
            addSubview(animationView)
            animationView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            
            let size = CGSize(width: lottieTrack.rect.normalizeWidth * renderSize.width,
                              height: lottieTrack.rect.normalizeHeight * renderSize.height)
            let centerX = lottieTrack.rect.normalizeCenter.x * renderSize.width
            let centerY = (1.0 - lottieTrack.rect.normalizeCenter.y) * renderSize.height
            frame.size = size
            frame.center = CGPoint(x: centerX, y: centerY)
//            snp.remakeConstraints { (make) in
//                make.center.equalTo(CGPoint(x: centerX, y: centerY))
//                make.size.equalTo(size)
//            }
        }
    }
    
    @objc func panGRHandler(_ sender: UIPanGestureRecognizer) {
        guard let lottieTrack = lottieTrack else { return }
        guard let superview = superview else { return }
        switch sender.state {
        case .began:
            superview.bringSubviewToFront(self)
//            log.debug(sender.location(in: self))
            break
            
        case .changed:
            let translation = sender.translation(in: self)
            
//            snp.updateConstraints { (make) in
            let newFrame = self.frame.applying(.init(translationX: translation.x, y: translation.y))
            frame = newFrame
            
            lottieTrack.rect.normalizeCenter.x = newFrame.midX / superview.bounds.width
            lottieTrack.rect.normalizeCenter.y = 1.0 - newFrame.midY / superview.bounds.height
//            log.debug(lottieTrack.rect.self.self)
//                print(self.frame, newFrame, translation)
//                make.center.equalTo(sender.location(in: self))
//            }
            sender.setTranslation(.zero, in: self)
            
        case .ended:
//            log.debug(sender.location(in: self))
            break
            
        default:
            break
        }
    }

}
