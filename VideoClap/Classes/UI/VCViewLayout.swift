//
//  VCViewLayout.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/23.
//

import UIKit

public protocol VCViewLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout {
    
    func layoutAttributes() -> [UICollectionViewLayoutAttributes]?
    
}

public class VCViewLayout: UICollectionViewLayout {
    
    weak var delegate: VCViewLayoutDelegate?
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return delegate?.layoutAttributes()
    }
    
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return delegate?.layoutAttributes()?.object(at: indexPath.item)
    }
    
}
