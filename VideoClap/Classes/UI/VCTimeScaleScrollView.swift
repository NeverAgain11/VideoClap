//
//  VCTimeScaleScrollView.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/14.
//

import AVFoundation
import UIKit

public class VCTimeScaleScrollView: UIScrollView, PinchGRHandler {
    
    public weak var scaleViewDelegate: VCTimeScaleViewDelegate? {
        didSet {
            contentView.delegate = scaleViewDelegate
        }
    }
    
    public lazy var timeControl: VCTimeControl = {
        let timeControl: VCTimeControl = .init()
        return timeControl
    }()
    
    internal lazy var contentView: VCTimeScaleView = {
        let mView = VCTimeScaleView(frame: .zero, timeControl: timeControl)
        return mView
    }()
    
    public var didScrollCallback: ((CMTime) -> Void)?
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commitInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commitInit() {
        isDirectionalLockEnabled = true
        showsHorizontalScrollIndicator = false
        delegate = self
        
        addSubview(contentView)
        
        contentView.snp.makeConstraints { (make) in
            make.height.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    public func handle(state: UIGestureRecognizer.State, scale: CGFloat) {
        switch state {
        case .began:
            self.delegate = nil
            
        case .changed:
//            storeScales.append(2.0 - sender.scale)
            setScale(scale)
            
        case .ended:
            setScale(scale)
            self.delegate = self
            
        default:
            break
        }
    }
    
    public func setScale(_ v: CGFloat) {
        timeControl.setScale(v * timeControl.scale)
        reloadData()
    }
    
    public func visibleRect() -> CGRect {
        let rect = CGRect(x: max(0, contentOffset.x), y: 0, width: bounds.width, height: bounds.height)
        return rect
    }
    
    public func fixPosition() {
        guard timeControl.duration.seconds != .zero else {
            return
        }
        let percentage = timeControl.currentTime.seconds / timeControl.duration.seconds
        let offsetX = CGFloat(percentage) * (contentSize.width) - contentInset.left
        contentOffset.x = offsetX
    }
    
    public func reloadData(fix: Bool = true) {
        contentSize.width = timeControl.maxLength
        if fix {
            fixPosition()
        }
        guard timeControl.intervalTime.value != 0 else {
            return
        }
        let datasourceCount = Int(timeControl.duration.value / timeControl.intervalTime.value)
        let cellWidth = timeControl.widthPerTimeVale * CGFloat(timeControl.intervalTime.value)
        contentView.datasourceCount = datasourceCount
        contentView.cellWidth = cellWidth
        contentView.reloadData(in: visibleRect())
    }
    
    public func setTime(currentTime: CMTime, duration: CMTime) {
        timeControl.setTime(currentTime: currentTime, duration: duration)
        reloadData()
    }
    
    public func setTime(currentTime: CMTime) {
        timeControl.setTime(currentTime: currentTime)
        
        if currentTime.isValid == false {
            return
        }
        timeControl.currentTime = min(max(.zero, currentTime), timeControl.duration)
        let percentage = timeControl.currentTime.seconds / timeControl.duration.seconds
        let offsetX = CGFloat(percentage) * (contentSize.width) - contentInset.left
        if offsetX.isNaN == false {
            contentOffset.x = offsetX
        }
    }
    
    public func setTime(duration: CMTime) {
        timeControl.setTime(duration: duration)
        reloadData()
    }
    
}

extension VCTimeScaleScrollView: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentSize.width.isZero {
            return
        }
        
        let percentage = (scrollView.contentOffset.x + self.contentInset.left) / (scrollView.contentSize.width)
        timeControl.currentTime = CMTime(seconds: Double(percentage) * timeControl.duration.seconds, preferredTimescale: VCTimeControl.timeBase)
        timeControl.currentTime = min(max(.zero, timeControl.currentTime), timeControl.duration)
        didScrollCallback?(timeControl.currentTime)
        reloadData(fix: false)
    }
    
}
