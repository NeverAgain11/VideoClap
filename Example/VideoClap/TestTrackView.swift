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
    
    lazy var models: [VCImageTrackViewModel] = {
        var models: [VCImageTrackViewModel] = []
        do {
            let model = VCImageTrackViewModel()
            model.timeControl = self.timeControl
            model.cellConfig = ImageCellConfig(imageTrack: imageTrack)
            model.cellSize = CGSize(width: height, height: height)
            models.append(model)
        }
        do {
            for _ in 0..<50 {
                let model = VCImageTrackViewModel()
                model.timeControl = self.timeControl
                model.cellConfig = VideoCellConfig(videoTrack: videoTrack)
                model.cellSize = CGSize(width: height, height: height)
                models.append(model)
            }
        }
        return models
    }()
    
    lazy var videoTrack: VCVideoTrackDescription = {
        let track = VCVideoTrackDescription()
        let source = CMTimeRange(start: 0, end: 100)
        let target = source
        track.timeMapping = CMTimeMapping(source: source, target: target)
        track.mediaURL = Bundle.main.url(forResource: "video0.mp4", withExtension: nil, subdirectory: "Mat")
        return track
    }()
    
    lazy var imageTrack: VCImageTrackDescription = {
        let track = VCImageTrackDescription()
        track.timeRange = CMTimeRange(start: 0, end: 100)
        track.mediaURL = Bundle.main.url(forResource: "watch-dogs-2-12000x8000-season-pass-hd-4k-8k-3105.JPG", withExtension: nil, subdirectory: "Mat")
        return track
    }()
    
    lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }()
    
    lazy var trackCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isScrollEnabled = false
        return collectionView
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
        scrollView.contentSize.width = totalWidth()
        scrollView.contentSize.height = height
        scrollView.contentInset.left = view.frame.width / 2
        scrollView.contentInset.right = scrollView.contentInset.left
        scrollView.contentOffset.x = -scrollView.contentInset.left
        trackCollectionView.frame.size = CGSize(width: scrollView.contentSize.width, height: height)
        trackCollectionView.reloadData()
        updateVisibleRect()
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
            models.forEach({ $0.isStopLoadThumbnail = true })
            scrollView.delegate = nil
            
        case .changed:
//            storeScales.append(2.0 - sender.scale)
            update(scale: scale)
            
        case .ended:
            models.forEach({ $0.isStopLoadThumbnail = false })
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
        scrollView.contentSize.width = totalWidth()
        trackCollectionView.frame.size = CGSize(width: scrollView.contentSize.width, height: height)
        fixPosition()
        updateVisibleRect()
    }
    
    func totalWidth() -> CGFloat {
        var width: CGFloat = 0
        for index in 0..<models.count {
            let size = collectionView(trackCollectionView, layout: layout, sizeForItemAt: IndexPath(item: index, section: 0))
            width += size.width
        }
        return width
    }
    
    func updateVisibleRect() {
        trackCollectionView.collectionViewLayout.invalidateLayout()
        let targetX = scrollView.contentOffset.x
        let rect = CGRect(x: max(0, targetX), y: 0, width: scrollView.bounds.width, height: height)
        let layoutAttributesForElements = trackCollectionView.collectionViewLayout.layoutAttributesForElements(in: rect) ?? []
        for layoutAttributes in layoutAttributesForElements {
            if layoutAttributes.frame.intersects(rect) {
                let model = models[layoutAttributes.indexPath.item]
                UIView.performWithoutAnimation {
                    model.minX = layoutAttributes.frame.origin.x
                    model.collectionView.frame.size = CGSize(width: model.expectWidth() ?? .zero, height: height)
                    model.reloadData(displayRect: rect)
                }
            }
        }
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
        updateVisibleRect()
    }
    
}

extension TestTrackView {
    
    func setupUI() {
        scrollView.addSubview(trackCollectionView)
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

extension TestTrackView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        let model = models[indexPath.item]
        if model.collectionView.superview != nil {
            model.collectionView.removeFromSuperview()
        }
        cell.contentView.addSubview(model.collectionView)
        model.collectionView.frame.size = CGSize(width: model.expectWidth() ?? .zero, height: cell.bounds.height)
        model.minX = cell.frame.origin.x
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let model = models[indexPath.item]
        let width = model.expectWidth() ?? .zero
        return CGSize(width: width, height: height)
    }
    
}
