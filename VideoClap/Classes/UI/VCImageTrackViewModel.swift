//
//  VCImageTrackViewModel.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/25.
//

import UIKit
import AVFoundation

public class VCImageTrackViewModel: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, VCMainTrackViewLayoutDelegate {
    
    public let layout: VCMainTrackViewLayout = {
        let layout = VCMainTrackViewLayout()
        return layout
    }()
    
    public lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    
    public var timeControl: VCTimeControl?
    
    public var displayRect: CGRect?
    
    public var cellSize: CGSize = .zero {
        didSet {
            cellConfig?.cellSizeUpdate(newCellSize: cellSize)
        }
    }
    
    public var minX: CGFloat = .zero
    
    public var isStopLoadThumbnail: Bool = false
    
    public var datasourceCount: Int = 0
    
    internal lazy var reuseIdentifierGroup: [String] = {
        var group: [String] = []
        group.append("VCImageCell")
        let width: CGFloat = 50
        for index in 0..<Int(ceil(UIScreen.main.bounds.width / width)) {
            group.append("VCImageCell\(index)")
        }
        return group
    }()
    
    public var cellConfig: CellConfig?
    
    public override init() {
        super.init()
        layout.delegate = self
        collectionView.isDirectionalLockEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        for reuseIdentifier in reuseIdentifierGroup {
            collectionView.register(VCImageCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        }
    }
    
    public func expectWidth() -> CGFloat? {
        guard let cellConfig = self.cellConfig else { return nil }
        guard cellSize.width.isZero == false else { return nil }
        guard let timeControl = timeControl else { return nil }
        let totalWidth: CGFloat = CGFloat(cellConfig.duration().value) * timeControl.widthPerTimeVale
        return totalWidth
    }
    
    public func reloadData() {
        guard cellSize.width.isZero == false else { return }
        guard let totalWidth: CGFloat = self.expectWidth() else { return }
        datasourceCount = Int(ceil(totalWidth / cellSize.width))
        collectionView.reloadData()
    }
    
    public func reloadData(displayRect: CGRect) {
        self.displayRect = displayRect
        layout.invalidateLayout()
        reloadData()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasourceCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.item % reuseIdentifierGroup.count
        let reuseIdentifier = reuseIdentifierGroup[index]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! VCImageCell
        cell.backgroundColor = collectionView.backgroundColor
        cell.contentView.backgroundColor = collectionView.backgroundColor
        cell.imageView.backgroundColor = collectionView.backgroundColor
        if cell.imageView.image == nil {
            cell.imageView.image = (collectionView.visibleCells as! [VCImageCell]).first(where: { $0.imageView.image != nil })?.imageView.image
        }
        if let cellConfig = self.cellConfig, let timeControl = self.timeControl, isStopLoadThumbnail == false {
            cellConfig.updateCell(cell: cell, index: indexPath.item, timeControl: timeControl)
        }
        return cell
    }
    
}
