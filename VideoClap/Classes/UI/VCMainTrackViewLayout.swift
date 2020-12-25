//
//  VCMainTrackViewLayout.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/25.
//

import UIKit

public class VCMainTrackViewLayout: UICollectionViewLayout {
    
    public var displayRect: CGRect?
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = self.collectionView as? MainTrackView else { return nil }
        guard var displayRect = displayRect else { return nil }
        
        displayRect.origin.x -= collectionView.frame.minX
        
        var attrs: [UICollectionViewLayoutAttributes] = []
        
        let cellSize: CGSize = collectionView.cellSize
        let cellWidth: CGFloat = cellSize.width
        let datasourceCount: Int = collectionView.datasourceCount
        
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
