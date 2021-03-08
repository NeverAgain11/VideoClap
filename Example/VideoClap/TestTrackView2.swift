//
//  TestTrackView2.swift
//  VideoClap_Example
//
//  Created by lai001 on 2021/3/1.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import SnapKit
import VideoClap
import AVFoundation

class TestTrackView2: UIViewController {
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.backgroundColor = #colorLiteral(red: 0.9764705882, green: 0.9764705882, blue: 0.9764705882, alpha: 1)
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    lazy var scaleView: VCTimeScaleView = {
        let view = VCTimeScaleView(frame: .zero, timeControl: timeControl)
        view.frame.size.height = 13
        view.frame.origin.y = 8
        return view
    }()
    
    lazy var mainTrackView: VCMainTrackView = {
        let view = VCMainTrackView(frame: .zero)
        view.viewDelegate = self
        view.timeControl = self.timeControl
        view.frame.size.height = 44
        view.frame.origin.y = 38
        return view
    }()
    
    lazy var models: [VCImageTrackViewModel] = {
        var models: [VCImageTrackViewModel] = []
//        for index in 0..<50 {
//            if Bool.random() {
//                let videoTrack = VCVideoTrackDescription()
//                videoTrack.mediaURL = resourceURL(filename: "video1.mp4")
//                var start: CMTime = .zero
//                if (0..<models.count).contains(index - 1) {
//                    start = models[index - 1].cellConfig!.targetTimeRange()!.end
//                }
//                let duration = AVAsset(url: videoTrack.mediaURL.unsafelyUnwrapped).duration
//                let source = CMTimeRange(start: 0, end: duration.seconds)
//                let target = CMTimeRange(start: start.seconds, duration: source.duration.seconds)
//                videoTrack.timeMapping = CMTimeMapping(source: source, target: target)
//                let model = VCImageTrackViewModel()
//                model.timeControl = self.timeControl
//                model.cellConfig = VideoCellConfig(videoTrack: videoTrack)
//                model.cellSize = CGSize(width: height, height: height)
//                models.append(model)
//            } else {
//                let videoTrack = VCVideoTrackDescription()
//                videoTrack.mediaURL = resourceURL(filename: "video0.mp4")
//                var start: CMTime = .zero
//                if (0..<models.count).contains(index - 1) {
//                    start = models[index - 1].cellConfig!.targetTimeRange()!.end
//                }
//                let duration = AVAsset(url: videoTrack.mediaURL.unsafelyUnwrapped).duration
//                let source = CMTimeRange(start: 0, end: duration.seconds)
//                let target = CMTimeRange(start: start.seconds, duration: source.duration.seconds)
//                videoTrack.timeMapping = CMTimeMapping(source: source, target: target)
//                let model = VCImageTrackViewModel()
//                model.timeControl = self.timeControl
//                model.cellConfig = VideoCellConfig(videoTrack: videoTrack)
//                model.cellSize = CGSize(width: height, height: height)
//                models.append(model)
//            }
//        }
        for index in 0..<4 {
            if Bool.random() {
                let imageTrack = VCImageTrackDescription()
                imageTrack.mediaURL = resourceURL(filename: "test4.jpg")
                var start: CMTime = .zero
                if (0..<models.count).contains(index - 1) {
                    start = models[index - 1].cellConfig!.targetTimeRange()!.end
                }
                imageTrack.timeRange = CMTimeRange(start: start.seconds, duration: 3.0)
                let model = VCImageTrackViewModel()
                model.timeControl = self.timeControl
                model.cellConfig = ImageCellConfig(imageTrack: imageTrack)
                model.cellSize = CGSize(width: height, height: height)
                models.append(model)
            } else {
                let imageTrack = VCImageTrackDescription()
                imageTrack.mediaURL = resourceURL(filename: "test3.jpg")
                var start: CMTime = .zero
                if (0..<models.count).contains(index - 1) {
                    start = models[index - 1].cellConfig!.targetTimeRange()!.end
                }
                imageTrack.timeRange = CMTimeRange(start: start.seconds, duration: 3.0)
                let model = VCImageTrackViewModel()
                model.timeControl = self.timeControl
                model.cellConfig = ImageCellConfig(imageTrack: imageTrack)
                model.cellSize = CGSize(width: height, height: height)
                models.append(model)
            }
        }
        return models
    }()
    
    lazy var pinchGR: UIPinchGestureRecognizer = {
        let pinchGR = UIPinchGestureRecognizer(target: self, action: #selector(pinchGRHandler(_:)))
        return pinchGR
    }()
    
    let height: CGFloat = 44
    
    let timeControl: VCTimeControl = VCTimeControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(scrollView)
        scrollView.addSubview(scaleView)
        scrollView.addSubview(mainTrackView)
        scrollView.snp.makeConstraints { (make) in
            make.left.width.centerY.equalToSuperview()
            make.height.equalTo(100)
        }
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        scrollView.contentInset.left = scrollView.bounds.width / 2.0
        scrollView.contentInset.right = scrollView.contentInset.left

        let duration = models.max { (lhs, rhs) -> Bool in
            return (lhs.cellConfig?.targetTimeRange()?.end ?? .zero) < (rhs.cellConfig?.targetTimeRange()?.end ?? .zero)
        }?.cellConfig?.targetTimeRange()?.end ?? .zero
        
        timeControl.setTime(duration: duration)
        timeControl.setScale(60)
        
        view.addGestureRecognizer(pinchGR)
        
        
        mainTrackView.layout.invalidateLayout()
        mainTrackView.collectionView.reloadData()
        
        reloadData(fix: false)
    }
    
    @objc internal func pinchGRHandler(_ sender: UIPinchGestureRecognizer) {
        handle(state: sender.state, scale: sender.scale)
        
        if sender.state == .changed {
            sender.scale = 1.0
        }
    }
    
    public func handle(state: UIGestureRecognizer.State, scale: CGFloat) {
        scrollView.delegate = nil
        defer {
            scrollView.delegate = self
        }
        
        switch state {
        case .began:
            models.forEach({ $0.isStopLoadThumbnail = true })
            
        case .changed:
//            storeScales.append(2.0 - sender.scale)
            timeControl.setScale(scale * timeControl.scale)
            mainTrackView.layout.invalidateLayout()
            reloadData()
        
        case .ended:
            timeControl.setScale(scale * timeControl.scale)
            models.forEach({ $0.isStopLoadThumbnail = false })
            mainTrackView.layout.invalidateLayout()
            reloadData()
            
        default:
            break
        }
    }
    
    func fixPosition() {
        let percentage = timeControl.currentTime.seconds / timeControl.duration.seconds
        let offsetX = CGFloat(percentage) * (scrollView.contentSize.width) - scrollView.contentInset.left
        scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
    }
    
    public func visibleRect() -> CGRect {
        let rect = CGRect(x: max(0, scrollView.contentOffset.x), y: 0, width: scrollView.bounds.width, height: scrollView.bounds.height)
        return rect
    }
    
    public func reloadData(fix: Bool = true) {
        scrollView.contentSize.width = timeControl.maxLength
        if fix {
            fixPosition()
        }
        guard timeControl.intervalTime.value != 0 else {
            return
        }
        let datasourceCount = Int(timeControl.duration.value / timeControl.intervalTime.value)
        let cellWidth = timeControl.widthPerTimeVale * CGFloat(timeControl.intervalTime.value)
        scaleView.datasourceCount = datasourceCount
        scaleView.cellWidth = cellWidth
        scaleView.reloadData(in: visibleRect())
        
        mainTrackView.frame.size.width = scrollView.contentSize.width
        mainTrackView.reloadData(in: visibleRect())
    }
    
}

extension TestTrackView2: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentSize.width.isZero {
            return
        }
        let percentage = (scrollView.contentOffset.x + scrollView.contentInset.left) / (scrollView.contentSize.width)
        var currentTime = CMTime(seconds: Double(percentage) * timeControl.duration.seconds, preferredTimescale: VCTimeControl.timeBase)
        currentTime = min(max(.zero, currentTime), timeControl.duration)
        timeControl.setTime(currentTime: currentTime)
        
        scaleView.reloadData(in: visibleRect())
        mainTrackView.reloadData(in: visibleRect())
    }
    
}

extension TestTrackView2: VCMainTrackViewDelegate {
    
    func dataSource() -> [VCImageTrackViewModel] {
        return self.models
    }
    
    func didSelectItemAt(_ model: VCImageTrackViewModel, index: Int) {
        
    }
    
    func preReloadModel(_ model: VCImageTrackViewModel, visibleRect: CGRect) {
        
    }
    
    func postReloadModel(_ model: VCImageTrackViewModel, visibleRect: CGRect) {
        
    }
    
}
