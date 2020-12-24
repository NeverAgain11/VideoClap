//
//  VCTimeScaleScrollView.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/14.
//

import AVFoundation
import UIKit

public class VCTimeScaleScrollView: UIScrollView, PinchGRHandler {
    
    public lazy var timeControl: VCTimeControl = {
        let timeControl: VCTimeControl = .init()
        return timeControl
    }()
    
    internal lazy var storeScales: [CGFloat] = []
    
    internal lazy var contentView: VCTimeScaleView = {
        let mView = VCTimeScaleView(frame: .zero, timeControl: timeControl)
        return mView
    }()
    
    private var reloadDataLimit = 0
    
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
        let limit = 2
        switch state {
        case .began:
            storeScales.removeAll()
            self.delegate = nil
            
        case .changed:
//            storeScales.append(2.0 - sender.scale)
            storeScales.append(scale)
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(delayChange), object: nil)
            if storeScales.count % limit == 0 {
                delayChange()
            } else {
                perform(#selector(delayChange), with: nil, afterDelay: 0.03)
            }
            
        case .ended:
            if storeScales.count % limit != 0 {
                delayChange()
            }
            self.delegate = self
            
        default:
            break
        }
    }
    
    @objc private func delayChange() {
        let storeScale = storeScales.reduce(1.0) { (result, scale) in
            return result * scale
        }
        storeScales.removeAll()
        setScale(timeControl.scale * storeScale)
    }
    
    private func validate() -> Bool {
        if timeControl.duration.seconds.isZero {
            return false
        }
        return true
    }
    
    public func setScale(_ v: CGFloat) {
        timeControl.setScale(v)
        
        guard validate() else {
            return
        }
        
        let datasourceCount = Int(timeControl.duration.value / timeControl.intervalTime.value)
        let cellWidth = timeControl.widthPerTimeVale * CGFloat(timeControl.intervalTime.value)
        let totalWidth = cellWidth * CGFloat(datasourceCount)
        let percentage = timeControl.currentTime.seconds / timeControl.duration.seconds
        let offsetX = CGFloat(percentage) * (totalWidth) - contentInset.left
        contentView.datasourceCount = datasourceCount
        contentView.cellWidth = cellWidth
        
        reloadData(targetX: offsetX)
        
        fixPosition()
    }
    
    private func fixPosition() {
        let percentage = timeControl.currentTime.seconds / timeControl.duration.seconds
        let offsetX = CGFloat(percentage) * (contentSize.width) - contentInset.left
        contentOffset.x = offsetX
    }
    
    public func reloadData() {
        reloadData(targetX: contentOffset.x)
    }
    
    private func reloadData(targetX: CGFloat) {
        let rect = CGRect(x: max(0, targetX), y: 0, width: self.bounds.width, height: self.bounds.height)
        contentView.reloadData(in: rect)
        contentSize.width = contentView.frame.size.width
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
        reloadDataLimit += 1
        if reloadDataLimit % 2 == 0 {
            reloadData()
        }
    }
    
}
