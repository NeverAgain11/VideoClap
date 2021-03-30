//
//  VCLottiePreview.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/21.
//

import AVFoundation
import SnapKit

public class VCLottiePreview: UIView {

    internal lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    internal lazy var panGR: UIPanGestureRecognizer = {
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(panGRHandler(_:)))
        panGR.delegate = self
        return panGR
    }()
    
    internal lazy var pinchGR: UIPinchGestureRecognizer = {
        let pinchGR = UIPinchGestureRecognizer(target: self, action: #selector(pinchGRHandler(_:)))
        pinchGR.delegate = self
        return pinchGR
    }()
    
    internal lazy var rotationGR: UIRotationGestureRecognizer = {
        let rotationGR = UIRotationGestureRecognizer(target: self, action: #selector(rotationGRHandler(_:)))
        rotationGR.delegate = self
        return rotationGR
    }()
    
    internal var lottieTrack: VCLottieTrackDescription?
    
    internal var renderSize: CGSize = .zero
    
    internal func setup(lottieTrack: VCLottieTrackDescription, renderSize: CGSize) {
        self.renderSize = renderSize
        self.lottieTrack = lottieTrack
        addGestureRecognizer(panGR)
        addGestureRecognizer(pinchGR)
        addGestureRecognizer(rotationGR)
        addSubview(imageView)
        
        imageView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        let size = CGSize(width: lottieTrack.rect.width * renderSize.width,
                          height: lottieTrack.rect.height * renderSize.height)
        let centerX = lottieTrack.rect.center.x * renderSize.width
        let centerY = (1.0 - lottieTrack.rect.center.y) * renderSize.height
        frame.size = size
        frame.center = CGPoint(x: centerX, y: centerY)
    }
    
    @objc internal func panGRHandler(_ sender: UIPanGestureRecognizer) {
        guard let lottieTrack = lottieTrack else { return }
        guard let superview = superview else { return }
        switch sender.state {
        case .began:
            superview.bringSubviewToFront(self)
            break
            
        case .changed:
            let translation = sender.translation(in: self)
            let newFrame = self.frame.applying(.init(translationX: translation.x, y: translation.y))
            frame = newFrame
            
            lottieTrack.rect.center.x = newFrame.midX / superview.bounds.width
            lottieTrack.rect.center.y = 1.0 - newFrame.midY / superview.bounds.height
            sender.setTranslation(.zero, in: self)
            
        case .ended:
            break
            
        default:
            break
        }
    }
    
    @objc internal func pinchGRHandler(_ sender: UIPinchGestureRecognizer) {
        guard let lottieTrack = lottieTrack else { return }
        switch sender.state {
        case .began:
            break
            
        case .changed:
            lottieTrack.rect.width = lottieTrack.rect.width * sender.scale
            lottieTrack.rect.height = lottieTrack.rect.height * sender.scale

            let newSize = CGSize(width: lottieTrack.rect.width * renderSize.width,
                                 height: lottieTrack.rect.height * renderSize.height)
            let centerX = lottieTrack.rect.center.x * renderSize.width
            let centerY = (1.0 - lottieTrack.rect.center.y) * renderSize.height
            frame.size = newSize
            frame.center = CGPoint(x: centerX, y: centerY)
            sender.scale = 1.0
            
        case .ended:
            break
            
        default:
            break
        }
    }
    
    @objc internal func rotationGRHandler(_ sender: UIRotationGestureRecognizer) {
        guard let lottieTrack = lottieTrack else { return }
        switch sender.state {
        case .began:
            break
            
        case .changed:
            lottieTrack.rotateRadian += sender.rotation
            imageView.transform = CGAffineTransform.identity.rotated(by: CGFloat(lottieTrack.rotateRadian))
            sender.rotation = 0.0
            
        case .ended:
            break
            
        default:
            break
        }
    }

}

extension VCLottiePreview: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIRotationGestureRecognizer {
            return true
        }
        if gestureRecognizer is UIRotationGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer {
            return true
        }
        return false
    }
    
}
