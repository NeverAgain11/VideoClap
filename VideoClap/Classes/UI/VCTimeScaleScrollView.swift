//
//  VCTimeScaleScrollView.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/14.
//

import AVFoundation
import UIKit

public class VCTimeScaleScrollView: UIScrollView, PinchGRHandler {
    
    public let timeBase: CMTimeScale = 600
    
    internal lazy var storeScales: [CGFloat] = []
    
    internal var cellWidth: CGFloat = 0.0
    
    /// 指示一个cell占用多少 time value
    internal var baseValue: CMTimeValue = 40
    
    internal var datasourceCount = 0
    
    let range0: Range<CGFloat> = 1..<10
    let range1: Range<CGFloat> = 10..<20
    let range2: Range<CGFloat> = 20..<24
    let range3: Range<CGFloat> = 24..<30
    let range4: Range<CGFloat> = 30..<60
    let range5: Range<CGFloat> = 60..<120
    let range6: Range<CGFloat> = 120..<200
    let range7: Range<CGFloat> = 200..<300
    let range8: ClosedRange<CGFloat> = 300...600
    
    public internal(set) lazy var currentTime: CMTime = CMTime(value: 0, timescale: timeBase)
    
    public internal(set) lazy var scale: CGFloat = 1
    
    public internal(set) lazy var duration: CMTime = CMTime(value: 0, timescale: timeBase)
    
    internal lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimumIntegerDigits = 2
        return formatter
    }()
    
    lazy var cells: [VCTimeScaleCell] = {
        let cells: [VCTimeScaleCell] = []
        return cells
    }()
    
    lazy var contentView: UIView = {
        let mView = UIView()
        return mView
    }()
    
    var reloadDataLimit = 0
    
    var didScrollCallback: ((_ scrollView: UIScrollView, CGFloat) -> Void)?
    
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
    
    internal func commitInit() {
        isDirectionalLockEnabled = true
        showsHorizontalScrollIndicator = false
        delegate = self
    }
    
    internal func makeDataSource() {
        var widthPerBaseValue: CGFloat
        let cellWidthRange: ClosedRange<CGFloat> = 80...120
        switch scale {
        case range0:
            baseValue = 6000
            widthPerBaseValue = scale.map(from: range0, to: cellWidthRange)
            
        case range1:
            baseValue = 3000
            widthPerBaseValue = scale.map(from: range1, to: cellWidthRange)
            
        case range2:
            baseValue = 2400
            widthPerBaseValue = scale.map(from: range2, to: cellWidthRange)
            
        case range3:
            baseValue = 1200
            widthPerBaseValue = scale.map(from: range3, to: cellWidthRange)
            
        case range4:
            baseValue = 600
            widthPerBaseValue = scale.map(from: range4, to: cellWidthRange)
            
        case range5:
            baseValue = 300
            widthPerBaseValue = scale.map(from: range5, to: cellWidthRange)

        case range6:
            baseValue = 100
            widthPerBaseValue = scale.map(from: range6, to: cellWidthRange)
            
        case range7:
            baseValue = 60
            widthPerBaseValue = scale.map(from: range7, to: cellWidthRange)
            
        case range8:
            baseValue = 40
            widthPerBaseValue = scale.map(from: range8, to: cellWidthRange)
            
        default:
            baseValue = 40
            widthPerBaseValue = scale.map(from: range8, to: cellWidthRange)
        }
        
        cellWidth = widthPerBaseValue
        
        datasourceCount = Int(duration.value / baseValue)
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
    
    @objc internal func delayChange() {
        let storeScale = storeScales.reduce(1.0) { (result, scale) in
            return result * scale
        }
        storeScales.removeAll()
        setScale(scale * storeScale)
    }
    
    public func setScale(_ v: CGFloat) {
        scale = min(600, max(1 , v))
        makeDataSource()
        if datasourceCount == 0 {
            return
        }
        contentInset.left = bounds.width / 2.0
        contentInset.right = contentInset.left
        let contentWidth: CGFloat = cellWidth * CGFloat(datasourceCount)
        contentSize.width = contentWidth
        let percentage = currentTime.seconds / duration.seconds
        let offsetX = CGFloat(percentage) * (contentSize.width) - contentInset.left
        setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
        
        reloadData()
    }
    
    func reloadData() {
        var currentIndex = Int(contentOffset.x / cellWidth)
        currentIndex = min(max(0, currentIndex), datasourceCount)
        
        let maxLow = ceil((frame.size.width + cellWidth * 2) / cellWidth)
        let upper = max(0, currentIndex - Int(maxLow) / 2)
        var low = 0
        
        low = min(datasourceCount, currentIndex + Int(maxLow))
        
        let exCellFrames: [CGRect] = cells.map({ $0.frame })
        
        for item in upper..<low {
            let x: CGFloat = CGFloat(item) * cellWidth
            let cellFrame = CGRect(x: x, y: 0, width: cellWidth, height: bounds.height)
            
            if exCellFrames.contains(cellFrame) {
                
            } else {
                let newCell = cellForItemAt(index: item)
                newCell.frame = cellFrame
                cells.append(newCell)
                addSubview(newCell)
            }
        }
        
        let left: CGFloat = CGFloat(upper) * cellWidth
        let right: CGFloat = CGFloat(low) * cellWidth
        
        let visibleRect: CGRect = CGRect(x: left, y: 0, width: right - left, height: self.bounds.height)
        
        for cell in cells {
            if cell.frame.intersects(visibleRect) {
                
            } else {
                cell.removeFromSuperview()
            }
        }
        
        cells = cells.filter({ $0.superview != nil })
    }
    
    private func cellForItemAt(index: Int) -> VCTimeScaleCell {
        let cell = VCTimeScaleCell()
        let time = CMTime(value: baseValue * Int64(index), timescale: timeBase)
        
        if time.value % 600 == 0 {
            cell.keyTimeLabel.text = format(time: time)
        } else {
            let seconds = time.value / 600
            let remaind = time.value - seconds * 600
            cell.keyTimeLabel.text = "\(remaind / 20)f"
        }
 
        return cell
    }
    
    public func setTime(currentTime: CMTime, duration: CMTime) {
        if currentTime.isValid == false || duration.isValid == false {
            return
        }
        self.duration = max(duration, .zero)
        self.currentTime = min(max(.zero, currentTime), self.duration)
        setScale(scale)
    }
    
    public func setTime(currentTime: CMTime) {
        if currentTime.isValid == false {
            return
        }
        self.currentTime = min(max(.zero, currentTime), self.duration)
        let percentage = self.currentTime.seconds / duration.seconds
        let offsetX = CGFloat(percentage) * (contentSize.width) - contentInset.left
        setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
    }
    
    public func setTime(duration: CMTime) {
        if duration.isValid == false {
            return
        }
        self.duration = max(duration, .zero)
        setScale(scale)
    }
    
    internal func format(time: CMTime) -> String {
        let minute = formatter.string(from: NSNumber(value: Int(time.seconds) / 60)) ?? "00"
        let second = formatter.string(from: NSNumber(value: Int(time.seconds) % 60)) ?? "00"
        let timeStr = "\(minute):\(second)"
        return timeStr
    }
    
}

extension VCTimeScaleScrollView: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentSize.width.isZero {
            return
        }
        
        let percentage = (scrollView.contentOffset.x + self.contentInset.left) / (scrollView.contentSize.width)
        didScrollCallback?(scrollView, percentage)
        currentTime = CMTime(seconds: Double(percentage) * duration.seconds, preferredTimescale: timeBase)
        currentTime = min(max(.zero, currentTime), duration)
        reloadDataLimit += 1
        if reloadDataLimit % 2 == 0 {
            reloadData()
        }
    }
    
}
