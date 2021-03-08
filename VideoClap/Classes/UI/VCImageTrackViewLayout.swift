//
//  VCMainTrackViewLayout.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/25.
//

import UIKit

public protocol VCImageTrackViewLayoutDelegate: NSObject {
    var displayRect: CGRect? { get set }
    var cellSize: CGSize { get set }
    var datasourceCount: Int { get set }
    func frame() -> CGRect
}

public class VCImageTrackViewLayout: UICollectionViewLayout {
    
    public weak var delegate: VCImageTrackViewLayoutDelegate?
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let delegate = self.delegate else { return nil }
        guard var displayRect = delegate.displayRect else { return nil }
        
        displayRect.origin.x -= delegate.frame().minX
        
        var attrs: [UICollectionViewLayoutAttributes] = []
        
        let cellSize: CGSize = delegate.cellSize
        let cellWidth: CGFloat = cellSize.width
        let datasourceCount: Int = delegate.datasourceCount
        
        let upper = max(0, Int(floor(displayRect.minX / cellWidth)) )
        let low = min(datasourceCount, Int(ceil(displayRect.maxX / cellWidth)) )

        if low <= upper {
            return nil
        }
        
        let y: CGFloat = 0
        for index in upper..<low {
            let x: CGFloat = CGFloat(index) * cellWidth
            let attr = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: 0))
            attr.frame = CGRect(origin: CGPoint(x: x, y: y), size: cellSize)
            attrs.append(attr)
        }
        return attrs
    }
    
    public override var collectionViewContentSize: CGSize {
        guard let collectionView = self.collectionView else { return .zero }
        return collectionView.bounds.size
    }
    
}
