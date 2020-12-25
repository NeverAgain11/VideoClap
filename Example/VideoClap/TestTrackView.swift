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

class TestTrackView: UIViewController {
    
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
    
    lazy var imageTrackView: VCImageTrackView = {
        let view = VCImageTrackView()
        view.backgroundColor = UIColor.lightGray
        return view
    }()
    
    lazy var videoTrack: VCVideoTrackDescription = {
        let track = VCVideoTrackDescription()
        let source = CMTimeRange(start: 0, end: 5)
        let target = source
        track.timeMapping = CMTimeMapping(source: source, target: target)
        track.mediaURL = Bundle.main.url(forResource: "video0.mp4", withExtension: nil, subdirectory: "Mat")
        return track
    }()
    
    lazy var imageTrack: VCImageTrackDescription = {
        let track = VCImageTrackDescription()
        track.timeRange = CMTimeRange(start: 5, end: 10)
        track.mediaURL = Bundle.main.url(forResource: "watch-dogs-2-12000x8000-season-pass-hd-4k-8k-3105.JPG", withExtension: nil, subdirectory: "Mat")
        return track
    }()
    
    internal lazy var pinchGR: UIPinchGestureRecognizer = {
        let pinchGR = UIPinchGestureRecognizer(target: self, action: #selector(pinchGRHandler(_:)))
        return pinchGR
    }()
    
    var timeControl = VCTimeControl()
    
    let height: CGFloat = 50
    
    init() {
        super.init(nibName: nil, bundle: nil)
        timeControl.setTime(currentTime: .zero, duration: CMTime(value: videoTrack.timeMapping.target.duration.value, timescale: VCTimeControl.timeBase))
        timeControl.setScale(timeControl.minScale)
        view.addGestureRecognizer(pinchGR)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        videoTrackView.timeControl = timeControl
        videoTrackView.cellSize = CGSize(width: height, height: height)
        videoTrackView.videoTrack = videoTrack
        videoTrackView.reloadData(displayRect: CGRect(x: 0, y: 0, width: view.bounds.width, height: height))
        videoTrackView.frame = CGRect(x: 0, y: 0, width: CGFloat(videoTrack.timeMapping.target.duration.value) * timeControl.widthPerTimeVale, height: height)
        
        imageTrackView.timeControl = timeControl
        imageTrackView.cellSize = CGSize(width: height, height: height)
        imageTrackView.imageTrack = imageTrack
        imageTrackView.reloadData(displayRect: CGRect(x: 0, y: 0, width: view.bounds.width, height: height))
        imageTrackView.frame = CGRect(x: videoTrackView.frame.maxX, y: 0, width: CGFloat(imageTrack.timeRange.duration.value) * timeControl.widthPerTimeVale, height: height)
        
        scrollView.contentSize.width = videoTrackView.frame.width + imageTrackView.frame.width
        scrollView.contentSize.height = height
        scrollView.contentInset.left = view.frame.width / 2
        scrollView.contentInset.right = scrollView.contentInset.left
        scrollView.contentOffset.x = -scrollView.contentInset.left
    }
    
    @objc internal func pinchGRHandler(_ sender: UIPinchGestureRecognizer) {
        handle(state: sender.state, scale: sender.scale)
        
        if sender.state == .changed {
            sender.scale = 1.0
        }
    }
    
    public func handle(state: UIGestureRecognizer.State, scale: CGFloat) {
        switch state {
        case .began:
            videoTrackView.isStopLoadThumbnail = true
            scrollView.delegate = nil
            
        case .changed:
//            storeScales.append(2.0 - sender.scale)
            update(scale: scale)
            
        case .ended:
            videoTrackView.isStopLoadThumbnail = false
            update(scale: 1.0)
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
    
    func update(scale: CGFloat) {
        if (timeControl.isReachMax && scale >= 1.0) || (timeControl.isReachMin && scale <= 1.0) {
            return
        }
        timeControl.setScale(timeControl.scale * scale)
        
        videoTrackView.frame = CGRect(x: 0, y: 0, width: CGFloat(videoTrack.timeMapping.target.duration.value) * timeControl.widthPerTimeVale, height: height)
        imageTrackView.frame = CGRect(x: videoTrackView.frame.maxX, y: 0, width: CGFloat(imageTrack.timeRange.duration.value) * timeControl.widthPerTimeVale, height: height)
        
        scrollView.contentSize.width = videoTrackView.frame.width + imageTrackView.frame.width
        
        fixPosition()
        
        let targetX = scrollView.contentOffset.x
        let rect = CGRect(x: max(0, targetX), y: 0, width: scrollView.bounds.width, height: scrollView.bounds.height)
        videoTrackView.reloadData(displayRect: rect)
        imageTrackView.reloadData(displayRect: rect)
    }
    
}

extension TestTrackView: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentSize.width.isZero {
            return
        }
        let percentage = (scrollView.contentOffset.x + scrollView.contentInset.left) / (scrollView.contentSize.width)
        var currentTime = CMTime(seconds: Double(percentage) * timeControl.duration.seconds, preferredTimescale: VCTimeControl.timeBase)
        currentTime = min(max(.zero, currentTime), timeControl.duration)
        timeControl.setTime(currentTime: currentTime)
        let targetX = scrollView.contentOffset.x
        let rect = CGRect(x: max(0, targetX), y: 0, width: scrollView.bounds.width, height: videoTrackView.bounds.height)
        videoTrackView.reloadData(displayRect: rect)
        imageTrackView.reloadData(displayRect: rect)
    }
    
}

extension TestTrackView {
    
    func setupUI() {
        scrollView.addSubview(videoTrackView)
        scrollView.addSubview(imageTrackView)
        view.addSubview(scrollView)
        setupConstraints()
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    func setupConstraints() {
        scrollView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(160)
            make.height.equalTo(height)
        }
    }
    
}
