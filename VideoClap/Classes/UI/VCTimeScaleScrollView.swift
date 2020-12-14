//
//  VCTimeScaleScrollView.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/14.
//

import AVFoundation
import UIKit

public class VCTimeScaleScrollView: UIScrollView {
    
    public let timeBase: CMTimeScale = 600
    
    let viewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        return layout
    }()
    
    internal lazy var pinchGR: UIPinchGestureRecognizer = {
        let pinchGR = UIPinchGestureRecognizer(target: self, action: #selector(pinchGRHandler(_:)))
        return pinchGR
    }()
    
    internal lazy var storeScales: [CGFloat] = []
    
    internal var cellWidth: CGFloat = 0.0
    
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
    
    internal var isPinching: Bool = false
    
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
        addGestureRecognizer(pinchGR)
    }
    
    internal func makeDataSource() {
        let widthPerTimeValue: CGFloat
        
        switch scale {
        case range0:
            baseValue = 6000
            widthPerTimeValue = scale.map(from: range0, to: 1...2)
            
        case range1:
            baseValue = 3000
            widthPerTimeValue = scale.map(from: range1, to: 1...2)
            
        case range2:
            baseValue = 2400
            widthPerTimeValue = scale.map(from: range2, to: 1...2)
            
        case range3:
            baseValue = 1200
            widthPerTimeValue = scale.map(from: range3, to: 1...2)
            
        case range4:
            baseValue = 600
            widthPerTimeValue = scale.map(from: range4, to: 1...2)
            
        case range5:
            baseValue = 300
            widthPerTimeValue = scale.map(from: range5, to: 1...2)

        case range6:
            baseValue = 100
            widthPerTimeValue = scale.map(from: range6, to: 1...2)
            
        case range7:
            baseValue = 60
            widthPerTimeValue = scale.map(from: range7, to: 1...2)
            
        case range8:
            baseValue = 40
            widthPerTimeValue = scale.map(from: range8, to: 1...2)
            
        default:
            baseValue = 40
            widthPerTimeValue = scale.map(from: range8, to: 1...2)
        }
        
        cellWidth = CGFloat(baseValue) * widthPerTimeValue
        
        cellWidth = cellWidth.map(from: CGFloat(baseValue)...CGFloat(baseValue * 2), to: 80...120)
        
        datasourceCount = Int(duration.value / baseValue)
    }
    
    @objc internal func pinchGRHandler(_ sender: UIPinchGestureRecognizer) {
        let limit = 2
        switch sender.state {
        case .began:
            isPinching = true
            storeScales.removeAll()
            
        case .changed:
//            storeScales.append(2.0 - sender.scale)
            storeScales.append(sender.scale)
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(delayChange), object: nil)
            if storeScales.count % limit == 0 {
                delayChange()
            } else {
                perform(#selector(delayChange), with: nil, afterDelay: 0.03)
            }
            sender.scale = 1.0
            
        case .ended:
            if storeScales.count % limit != 0 {
                delayChange()
            }
            isPinching = false
            
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
        subviews.forEach({ $0.removeFromSuperview() })
        var currentIndex = Int(contentOffset.x / cellWidth)
        currentIndex = min(max(0, currentIndex), datasourceCount)
        
        let upper = max(0, currentIndex - 5)
        var low = 0
        
        if upper == 0 {
            low = min(datasourceCount, currentIndex + 17)
        } else {
            low = min(datasourceCount, currentIndex + 12)
        }
        
        for item in upper..<low {
            let x: CGFloat = CGFloat(item) * cellWidth
            let cellFrame = CGRect(x: x, y: 0, width: cellWidth, height: bounds.height)

            let time = CMTime(value: baseValue * Int64(item), timescale: timeBase)
            
            let label = UILabel(frame: cellFrame)
            label.text = "・"
            label.textColor = UIColor.lightText
            label.textAlignment = .center
            addSubview(label)
            
            let keyTimeLabel = UILabel()
            keyTimeLabel.textColor = UIColor.lightText
            keyTimeLabel.textAlignment = .center
            keyTimeLabel.backgroundColor = self.backgroundColor
            addSubview(keyTimeLabel)
            
            if time.value % 600 == 0 {
                keyTimeLabel.text = format(time: time)
            } else {
                let seconds = time.value / 600
                let remaind = time.value - seconds * 600
                keyTimeLabel.text = "\(remaind / 20)f"
            }
            
            keyTimeLabel.sizeToFit()
            keyTimeLabel.center = CGPoint(x: cellFrame.origin.x, y: bounds.midY)
        }
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
        if scrollView.contentSize.width.isZero || isPinching {
            return
        }
        let percentage = (scrollView.contentOffset.x + self.contentInset.left) / (scrollView.contentSize.width)
        currentTime = CMTime(seconds: Double(percentage) * duration.seconds, preferredTimescale: timeBase)
        currentTime = min(max(.zero, currentTime), duration)
        reloadDataLimit += 1
        if reloadDataLimit % 2 == 0 {
            reloadData()
        }
    }
    
}
