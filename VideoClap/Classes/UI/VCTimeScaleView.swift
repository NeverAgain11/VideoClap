//
//  VCTimeScaleView.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/22.
//

import UIKit
import SnapKit
import AVFoundation

public class VCTimeScaleView: UIView {
    
    public let timeControl: VCTimeControl
    
    internal lazy var cellModels: [VCTimeScaleCellModel] = {
        let cells: [VCTimeScaleCellModel] = []
        return cells
    }()
    
    internal lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimumIntegerDigits = 2
        return formatter
    }()
    
    public var datasourceCount = 0
    
    public var cellWidth: CGFloat = 0
    
    public init(frame: CGRect, timeControl: VCTimeControl) {
        self.timeControl = timeControl
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func validate() -> Bool {
        if datasourceCount < 0 || cellWidth <= 0 {
            return false
        }
        return true
    }
    
    public func reloadData(in rect: CGRect) {
        guard validate() else {
            return
        }
        frame.size.width = timeControl.maxLength
        guard let attributes = layoutAttributesForElements(in: rect) else {
            return
        }
        cellModels.forEach({ $0.dotLabel.removeFromSuperview(); $0.keyTimeLabel.removeFromSuperview() })
        let newCells = attributes.map { (attribute) -> VCTimeScaleCellModel in
            let cell = cellForItemAt(index: attribute.indexPath.item)
            addSubview(cell.keyTimeLabel)
            addSubview(cell.dotLabel)
            cell.dotLabel.sizeToFit()
            cell.keyTimeLabel.sizeToFit()
            cell.dotLabel.center = attribute.frame.center
            cell.keyTimeLabel.center = CGPoint(x: attribute.frame.minX, y: attribute.frame.midY)
            return cell
        }
        cellModels = newCells
    }
    
    private func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let upper = max(0, Int(floor(rect.minX / cellWidth)) )
        let low = min(datasourceCount, Int(ceil(rect.maxX / cellWidth)) )
        var attributes: [UICollectionViewLayoutAttributes] = []
        if low <= upper {
            let attr = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: 0, section: 0))
            attr.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: cellWidth, height: self.bounds.height))
            attributes.append(attr)
            return attributes
        }
        let cellSize = CGSize(width: cellWidth, height: self.bounds.height)
        let y: CGFloat = 0
        for index in upper...low {
            let x: CGFloat = CGFloat(index) * cellWidth
            let attr = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: 0))
            attr.frame = CGRect(origin: CGPoint(x: x, y: y), size: cellSize)
            attributes.append(attr)
        }
        return attributes
    }
    
    private func cellForItemAt(index: Int) -> VCTimeScaleCellModel {
        let cell = VCTimeScaleCellModel()
        let time = CMTime(value: timeControl.intervalTime.value * Int64(index), timescale: VCTimeControl.timeBase)
        
        if time.value % 600 == 0 {
            cell.keyTimeLabel.text = format(time: time)
        } else {
            let seconds = time.value / 600
            let remaind = time.value - seconds * 600
            cell.keyTimeLabel.text = "\(remaind / 20)f"
        }
        if index == datasourceCount {
            cell.dotLabel.isHidden = true
        } else {
            cell.dotLabel.isHidden = false
        }
        return cell
    }
    
    private func format(time: CMTime) -> String {
        let minute = formatter.string(from: NSNumber(value: Int(time.seconds) / 60)) ?? "00"
        let second = formatter.string(from: NSNumber(value: Int(time.seconds) % 60)) ?? "00"
        let timeStr = "\(minute):\(second)"
        return timeStr
    }
    
}
