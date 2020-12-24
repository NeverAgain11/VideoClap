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
    
    internal lazy var cells: [VCTimeScaleCell] = {
        let cells: [VCTimeScaleCell] = []
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
        if datasourceCount <= 0 || cellWidth <= 0 {
            return false
        }
        return true
    }
    
    public func reloadData(in rect: CGRect) {
        guard validate() else {
            return
        }
        frame.size.width = cellWidth * CGFloat(datasourceCount)
        guard let attributes = layoutAttributesForElements(in: rect) else {
            return
        }
        cells.forEach({ $0.removeFromSuperview() })
        let newCells = attributes.map { (attribute) -> VCTimeScaleCell in
            let cell = cellForItemAt(index: attribute.indexPath.item, attribute: attribute);
            addSubview(cell);
            return cell;
        }
        cells = newCells
    }
    
    private func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let upper = max(0, Int(floor(rect.minX / cellWidth)) )
        let low = min(datasourceCount, Int(ceil(rect.maxX / cellWidth)) )
        var attributes: [UICollectionViewLayoutAttributes] = []
        if low <= upper {
            return nil
        }
        let cellSize = CGSize(width: cellWidth, height: self.bounds.height)
        let y: CGFloat = 0
        for index in upper..<low {
            let x: CGFloat = CGFloat(index) * cellWidth
            let attr = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: 0))
            attr.frame = CGRect(origin: CGPoint(x: x, y: y), size: cellSize)
            attributes.append(attr)
        }
        return attributes
    }
    
    private func cellForItemAt(index: Int, attribute: UICollectionViewLayoutAttributes) -> VCTimeScaleCell {
        let cell = VCTimeScaleCell(frame: attribute.frame)
        let time = CMTime(value: timeControl.intervalTime.value * Int64(index), timescale: VCTimeControl.timeBase)
        
        if time.value % 600 == 0 {
            cell.keyTimeLabel.text = format(time: time)
        } else {
            let seconds = time.value / 600
            let remaind = time.value - seconds * 600
            cell.keyTimeLabel.text = "\(remaind / 20)f"
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
