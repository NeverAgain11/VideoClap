//
//  VCReorderableLayout.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/25.
//

import UIKit

public protocol VCReorderableLayoutDelegate: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, at: IndexPath, willMoveTo toIndexPath: IndexPath)
    func collectionView(_ collectionView: UICollectionView, at: IndexPath, didMoveTo toIndexPath: IndexPath)
    func collectionView(_ collectionView: UICollectionView, allowMoveAt indexPath: IndexPath) -> Bool
    func collectionView(_ collectionView: UICollectionView, at: IndexPath, canMoveTo: IndexPath) -> Bool
    
    func collectionView(_ collectionView: UICollectionView, collectionView layout: VCReorderableLayout, willBeginDraggingItemAt indexPath: IndexPath)
    func collectionView(_ collectionView: UICollectionView, collectionView layout: VCReorderableLayout, didBeginDraggingItemAt indexPath: IndexPath)
    func collectionView(_ collectionView: UICollectionView, collectionView layout: VCReorderableLayout, willEndDraggingItemTo indexPath: IndexPath)
    func collectionView(_ collectionView: UICollectionView, collectionView layout: VCReorderableLayout, didEndDraggingItemTo indexPath: IndexPath)
}

public extension VCReorderableLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, at: IndexPath, willMoveTo toIndexPath: IndexPath) {}
    func collectionView(_ collectionView: UICollectionView, at: IndexPath, didMoveTo toIndexPath: IndexPath) {}
    func collectionView(_ collectionView: UICollectionView, allowMoveAt indexPath: IndexPath) -> Bool {
        return true
    }
    func collectionView(_ collectionView: UICollectionView, at: IndexPath, canMoveTo: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, collectionView layout: VCReorderableLayout, willBeginDraggingItemAt indexPath: IndexPath) {}
    func collectionView(_ collectionView: UICollectionView, collectionView layout: VCReorderableLayout, didBeginDraggingItemAt indexPath: IndexPath) {}
    func collectionView(_ collectionView: UICollectionView, collectionView layout: VCReorderableLayout, willEndDraggingItemTo indexPath: IndexPath) {}
    func collectionView(_ collectionView: UICollectionView, collectionView layout: VCReorderableLayout, didEndDraggingItemTo indexPath: IndexPath) {}
}

open class VCReorderableLayout: UICollectionViewFlowLayout {
    
    public weak var delegate: VCReorderableLayoutDelegate? {
        get { return collectionView?.delegate as? VCReorderableLayoutDelegate }
        set { collectionView?.delegate = newValue }
    }
    
    fileprivate var displayLink: CADisplayLink?
    
    fileprivate var cellFakeView: VCCellFakeView?
    
    public var scrollSpeedValue: CGFloat = 10.0
    
    fileprivate var cancelDragToIndexPath: IndexPath?
    
    fileprivate var _scrollDirection: CGFloat = 1
    
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributesArray = super.layoutAttributesForElements(in: rect) else { return nil }
        attributesArray.filter {
            $0.representedElementCategory == .cell
        }.filter {
            $0.indexPath == (cellFakeView?.indexPath)
        }.forEach {
            $0.alpha = 0
        }
        return attributesArray
    }
    
    fileprivate func setUpDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
        displayLink = CADisplayLink(target: self, selector: #selector(VCReorderableLayout.continuousScroll))
        displayLink!.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
    }
    
    fileprivate func invalidateDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    fileprivate func beginScrollIfNeeded() {
        guard let cellFakeView = self.cellFakeView else { return }
        let midXAtScreen = UIScreen.main.bounds.midX
        let cellFakeViewGlobalRect = cellFakeView.convert(cellFakeView.bounds, to: nil)
        let offset = cellFakeViewGlobalRect.midX - midXAtScreen
        let distance = abs(cellFakeViewGlobalRect.midX.distance(to: midXAtScreen))
        if distance > (UIScreen.main.bounds.width / 2.0) - 20 {
            if offset < 0 {
                _scrollDirection = -1
            } else {
                _scrollDirection = 1
            }
            setUpDisplayLink()
        } else {
            invalidateDisplayLink()
        }
    }
    
    fileprivate func moveItemIfNeeded() {
        guard let collectionView = self.collectionView else { return }
        guard let fakeCell = cellFakeView,
              let atIndexPath = fakeCell.indexPath,
              let toIndexPath = collectionView.indexPathForItem(at: fakeCell.center) else {
            return
        }
        
        guard atIndexPath != toIndexPath else { return }
        
        if let canMove = delegate?.collectionView(collectionView, at: atIndexPath, canMoveTo: toIndexPath), !canMove {
            return
        }
        cancelDragToIndexPath = toIndexPath
        delegate?.collectionView(collectionView, at: atIndexPath, willMoveTo: toIndexPath)
        
        collectionView.performBatchUpdates({
            fakeCell.indexPath = toIndexPath
            collectionView.deleteItems(at: [atIndexPath])
            collectionView.insertItems(at: [toIndexPath])
            self.delegate?.collectionView(collectionView, at: atIndexPath, didMoveTo: toIndexPath)
        }, completion:nil)
    }
    
    @objc internal func continuousScroll() {
        guard let collectionView = self.collectionView else { return }
        let midXAtScreen = UIScreen.main.bounds.midX
        var collectionViewGlobalRect = collectionView.convert(collectionView.bounds, to: nil)
        guard collectionViewGlobalRect.minX <= midXAtScreen && collectionViewGlobalRect.maxX >= midXAtScreen else {
            return
        }
        let scrollRate = _scrollDirection * self.scrollSpeedValue
        var newRect = collectionView.frame
        newRect.origin.x -= scrollRate
        let oldX = collectionView.frame.origin.x
        collectionView.frame.origin.x -= scrollRate
        collectionViewGlobalRect = collectionView.convert(collectionView.bounds, to: nil)
        if collectionViewGlobalRect.minX <= midXAtScreen && collectionViewGlobalRect.maxX >= midXAtScreen {
            self.cellFakeView?.center.x += scrollRate
        } else {
            collectionView.frame.origin.x = oldX
        }
        moveItemIfNeeded()
    }
    
    private func cancelDrag() {
        guard let cellFakeView = self.cellFakeView else { return }
        guard let collectionView = self.collectionView else { return }
        if let toIndexPath = cancelDragToIndexPath {
            self.delegate?.collectionView(self.collectionView!, collectionView: self, willEndDraggingItemTo: toIndexPath)
        }
        collectionView.scrollsToTop = true
        invalidateDisplayLink()
        cellFakeView.removeFromSuperview()
        self.cellFakeView = nil
        self.invalidateLayout()
        if let toIndexPath = self.cancelDragToIndexPath {
            self.delegate?.collectionView(collectionView, collectionView: self, didEndDraggingItemTo: toIndexPath)
        }
    }
    
    // MARK: - Support for reordering
    /// // returns NO if reordering was prevented from beginning - otherwise YES
    @discardableResult
    public func beginInteractiveMovementForItem(at indexPath: IndexPath) -> Bool {
        guard let collectionView = self.collectionView else { return false }
        if delegate?.collectionView(self.collectionView!, allowMoveAt: indexPath) == false {
            return false
        }
        delegate?.collectionView(collectionView, collectionView: self, willBeginDraggingItemAt: indexPath)
        collectionView.scrollsToTop = false
        guard let currentCell = collectionView.cellForItem(at: indexPath) else {
            return false
        }
        let cellFakeView = VCCellFakeView(cell: currentCell)
        cellFakeView.indexPath = indexPath
        self.cellFakeView = cellFakeView
        collectionView.addSubview(cellFakeView)
        invalidateLayout()
        delegate?.collectionView(collectionView, collectionView: self, didBeginDraggingItemAt: indexPath)
        return true
    }
    
    public func updateInteractiveMovementTargetPosition(_ targetPosition: CGPoint) {
        if let cellFakeView = cellFakeView {
            cellFakeView.center.x = targetPosition.x
            cellFakeView.center.y = targetPosition.y
            
            beginScrollIfNeeded()
            moveItemIfNeeded()
        }
    }
    
    public func endInteractiveMovement() {
        cancelDrag()
        invalidateDisplayLink()
        cancelDragToIndexPath = nil
    }
    
}

private class VCCellFakeView: UIView {
    
    weak var cell: UICollectionViewCell?
    
    var cellFakeImageView: UIImageView?
    
    fileprivate var indexPath: IndexPath?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(cell: UICollectionViewCell) {
        super.init(frame: cell.frame)
        
        self.cell = cell
        
        cellFakeImageView = UIImageView(frame: self.bounds)
        cellFakeImageView?.contentMode = UIView.ContentMode.scaleAspectFill
        cellFakeImageView?.autoresizingMask = [.flexibleWidth , .flexibleHeight]
        cellFakeImageView?.image = getCellImage()
        
        addSubview(cellFakeImageView!)
    }
    
    fileprivate func getCellImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(cell!.bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        cell!.drawHierarchy(in: cell!.bounds, afterScreenUpdates: true)
        
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
    
}
