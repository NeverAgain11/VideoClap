//
//  MainTrackView.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/25.
//

import UIKit

public class MainTrackView: UICollectionView {
    
    public var timeControl: VCTimeControl?
    
    internal let layout: VCMainTrackViewLayout = {
        let layout = VCMainTrackViewLayout()
        return layout
    }()
    
    public var cellSize: CGSize = .zero
    
    internal var datasourceCount: Int = 0
    
    internal lazy var reuseIdentifierGroup: [String] = {
        var group: [String] = []
        group.append("VCImageCell")
        for index in 0..<Int(ceil(UIScreen.main.bounds.width / 50)) {
            group.append("VCImageCell\(index)")
        }
        return group
    }()
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public init(frame: CGRect) {
        super.init(frame: frame, collectionViewLayout: layout)
        commitInit()
    }
    
    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        commitInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commitInit() {
        isDirectionalLockEnabled = true
        showsHorizontalScrollIndicator = false
        for reuseIdentifier in reuseIdentifierGroup {
            register(VCImageCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        }
    }
    
}
