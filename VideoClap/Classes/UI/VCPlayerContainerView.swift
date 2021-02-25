//
//  VCPlayerContainerView.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/23.
//

import SSPlayer
import AVFoundation

public class VCPlayerContainerView: UIView {
    
    public weak var player: VCPlayer?
    
    public lazy var playerView: SSPlayerView = {
        let playerView = SSPlayerView(player: player)
        return playerView
    }()
    
    lazy var renderView: UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var layout: VCViewLayout = {
        let layout = VCViewLayout()
        layout.delegate = player
        return layout
    }()
    
    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.dataSource = player
        view.delegate = player
        view.register(VCPreviewCell.classForCoder(), forCellWithReuseIdentifier: "VCPreviewCell")
        view.backgroundColor = .clear
        return view
    }()
    
    public convenience init(player: VCPlayer) {
        self.init(frame: .zero, player: player)
    }
    
    public init(frame: CGRect, player: VCPlayer) {
        self.player = player
        super.init(frame: frame)
        addSubview(playerView)
        addSubview(renderView)
        addSubview(collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        playerView.player = nil
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if let _player = self.player {
            let rect = AVMakeRect(aspectRatio: _player.videoClap.videoDescription.renderSize, insideRect: self.bounds)
            playerView.frame = rect
            renderView.frame = rect
            collectionView.frame = rect
        }
    }
    
    public func reloadDataWithoutAnimation() {
        UIView.performWithoutAnimation {
            self.collectionView.reloadData()
        }
    }
    
}
