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
    
    fileprivate var scrollDirction: CGFloat = 1
    
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributesArray = super.layoutAttributesForElements(in: rect) else { return nil }
        
        attributesArray.filter {
            $0.representedElementCategory == .cell
        }.filter {
            $0.indexPath == (cellFakeView?.indexPath)
        }.forEach {
            // reordering cell alpha
            
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
    
    // begein scroll
    fileprivate func beginScrollIfNeeded() {
        guard let cellFakeView = self.cellFakeView else { return }
        let midXAtScreen = UIScreen.main.bounds.midX
        let cellFakeViewGlobalRect = cellFakeView.convert(cellFakeView.bounds, to: nil)
        let offset = cellFakeViewGlobalRect.midX - midXAtScreen
        let distance = abs(cellFakeViewGlobalRect.midX.distance(to: midXAtScreen))
        
        if distance > (UIScreen.main.bounds.width / 2.0) - 20 {
            if offset < 0 {
                scrollDirction = -1
            } else {
                scrollDirction = 1
            }
            setUpDisplayLink()
        } else {
            invalidateDisplayLink()
        }
    }
    
    // move item
    fileprivate func moveItemIfNeeded() {
        guard let collectionView = self.collectionView else { return }
        guard let fakeCell = cellFakeView,
              let atIndexPath = fakeCell.indexPath,
              let toIndexPath = collectionView.indexPathForItem(at: fakeCell.center) else {
            return
        }
        
        guard atIndexPath != toIndexPath else { return }
        
        // can move item
        if let canMove = delegate?.collectionView(collectionView, at: atIndexPath, canMoveTo: toIndexPath), !canMove {
            return
        }
        cancelDragToIndexPath = toIndexPath
        // will move item
        delegate?.collectionView(collectionView, at: atIndexPath, willMoveTo: toIndexPath)
        
        guard let attribute = self.layoutAttributesForItem(at: toIndexPath) else {
            return
        }
        collectionView.performBatchUpdates({
            fakeCell.indexPath = toIndexPath
//            fakeCell.cellFrame = attribute.frame
            fakeCell.changeBoundsIfNeeded(attribute.bounds)
            
            collectionView.deleteItems(at: [atIndexPath])
            collectionView.insertItems(at: [toIndexPath])
            
            // did move item
            self.delegate?.collectionView(collectionView, at: atIndexPath, didMoveTo: toIndexPath)
        }, completion: nil)
    }
    
    @objc internal func continuousScroll() {
        guard let collectionView = self.collectionView else { return }
        let midXAtScreen = UIScreen.main.bounds.midX
        
        var collectionViewGlobalRect = collectionView.convert(collectionView.bounds, to: nil)
        
        guard collectionViewGlobalRect.minX <= midXAtScreen && collectionViewGlobalRect.maxX >= midXAtScreen else {
            return
        }
        
        let scrollRate = scrollDirction * self.scrollSpeedValue
        
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
        
        // will end drag item
        if let toIndexPath = cancelDragToIndexPath {
            self.delegate?.collectionView(self.collectionView!, collectionView: self, willEndDraggingItemTo: toIndexPath)
        }
        
        collectionView.scrollsToTop = true
        
        invalidateDisplayLink()
        
        //        cellFakeView!.pushBackView {
        cellFakeView.removeFromSuperview()
        self.cellFakeView = nil
        self.invalidateLayout()
        
        // did end drag item
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
        
        // will begin drag item
        delegate?.collectionView(collectionView, collectionView: self, willBeginDraggingItemAt: indexPath)
        collectionView.scrollsToTop = false
        
        guard let currentCell = collectionView.cellForItem(at: indexPath) else {
            return false
        }
        
        let cellFakeView = VCCellFakeView(cell: currentCell)
        cellFakeView.indexPath = indexPath
//        cellFakeView.originalCenter = currentCell.center
//        cellFakeView.cellFrame = layoutAttributesForItem(at: indexPath)?.frame
        self.cellFakeView = cellFakeView
        collectionView.addSubview(cellFakeView)
        
        invalidateLayout()
        
        // did begin drag item
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
    
    lazy var cellFakeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.autoresizingMask = [.flexibleWidth , .flexibleHeight]
        return imageView
    }()
    
    fileprivate var indexPath: IndexPath?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(cell: UICollectionViewCell) {
        super.init(frame: cell.frame)
        cellFakeImageView.image = getCellImage(cell: cell)
        cellFakeImageView.frame = self.bounds
        addSubview(cellFakeImageView)
    }
    
    func changeBoundsIfNeeded(_ bounds: CGRect) {
        if self.bounds.equalTo(bounds) { return }
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: {
                self.bounds = bounds
            },
            completion: nil
        )
    }
    
    fileprivate func getCellImage(cell: UICollectionViewCell) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(cell.bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        cell.drawHierarchy(in: cell.bounds, afterScreenUpdates: true)
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
    
}
