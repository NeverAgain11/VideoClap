//
//  TestTrackView.swift
//  VideoClap_Example
//
//  Created by lai001 on 2020/12/18.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import VideoClap
import AVFoundation

class TestTrackView: UIViewController, UIScrollViewDelegate {
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        return scrollView
    }()
    
    lazy var videoTrackView: VCVideoTrackView = {
        let view = VCVideoTrackView()
        view.backgroundColor = UIColor.lightGray
        return view
    }()
    
    lazy var track: VCVideoTrackDescription = {
        let track = VCVideoTrackDescription()
        let source = CMTimeRange(start: 0, end: 5.1)
        let target = source
        track.timeMapping = CMTimeMapping(source: source, target: target)
        track.mediaURL = Bundle.main.url(forResource: "video0.mp4", withExtension: nil, subdirectory: "Mat")
        return track
    }()
    
    internal lazy var pinchGR: UIPinchGestureRecognizer = {
        let pinchGR = UIPinchGestureRecognizer(target: self, action: #selector(pinchGRHandler(_:)))
        return pinchGR
    }()
    
    var timeControl = VCTimeControl()
    
    internal lazy var storeScales: [CGFloat] = []
    
    let height: CGFloat = 50
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timeControl.setTime(currentTime: .zero, duration: CMTime(value: track.timeMapping.target.duration.value, timescale: VCTimeControl.timeBase))
        timeControl.setScale(59.9)
        setupUI()
        view.addGestureRecognizer(pinchGR)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        videoTrackView.cellSize = CGSize(width: height, height: height)
        videoTrackView.widthPerTimeValue = timeControl.widthPerTimeVale
        videoTrackView.videoTrack = track
        videoTrackView.reloadData()
        
        let totalWidth: CGFloat = CGFloat(track.timeMapping.target.duration.value) * videoTrackView.widthPerTimeValue
        
        videoTrackView.frame = CGRect(x: 0, y: 0, width: totalWidth, height: height)
        scrollView.contentSize.width = videoTrackView.frame.width
        scrollView.contentSize.height = height
    }
    
    @objc internal func pinchGRHandler(_ sender: UIPinchGestureRecognizer) {
        handle(state: sender.state, scale: sender.scale)
        
        if sender.state == .changed {
            sender.scale = 1.0
        }
    }
    
    public func handle(state: UIGestureRecognizer.State, scale: CGFloat) {
        let limit = 10
        switch state {
        case .began:
            storeScales.removeAll()
            scrollView.delegate = nil
            
        case .changed:
//            storeScales.append(2.0 - sender.scale)
            storeScales.append(scale)
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(delayChange), object: nil)
            if storeScales.count % limit == 0 {
                delayChange()
            } else {
                perform(#selector(delayChange), with: nil, afterDelay: 0.1)
            }
            
        case .ended:
            if storeScales.count % limit != 0 {
                delayChange()
            }
            scrollView.delegate = self
            
        default:
            break
        }
    }
    
    func fixPosition() {
        let percentage = timeControl.currentTime.seconds / timeControl.duration.seconds
        let offsetX = CGFloat(percentage) * (scrollView.contentSize.width) - scrollView.contentInset.left
        scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
    }
    
    @objc func delayChange() {
        let storeScale = storeScales.reduce(1.0) { (result, scale) in
            return result * scale
        }
        storeScales.removeAll()
        timeControl.setScale(timeControl.scale * storeScale)
        videoTrackView.widthPerTimeValue = timeControl.widthPerTimeVale
        let totalWidth: CGFloat = CGFloat(track.timeMapping.target.duration.value) * videoTrackView.widthPerTimeValue
        videoTrackView.frame = CGRect(x: 0, y: 0, width: totalWidth, height: height)
        scrollView.contentSize.width = videoTrackView.frame.width
        scrollView.contentSize.height = height
        fixPosition()
        videoTrackView.reloadData()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentSize.width.isZero {
            return
        }
        let percentage = (scrollView.contentOffset.x + scrollView.contentInset.left) / (scrollView.contentSize.width)
        var currentTime = CMTime(seconds: Double(percentage) * timeControl.duration.seconds, preferredTimescale: VCTimeControl.timeBase)
        currentTime = min(max(.zero, currentTime), timeControl.duration)
        timeControl.setTime(currentTime: currentTime)
    }
    
}

extension TestTrackView {
    
    func setupUI() {
        scrollView.addSubview(videoTrackView)
        view.addSubview(scrollView)
        setupConstraints()
    }
    
    func setupConstraints() {
        scrollView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(160)
            make.height.equalTo(height)
        }
    }
    
}
