//
//  VCPlayerContainerView.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/23.
//

import SSPlayer
import AVFoundation

public class VCPlayerContainerView: UIView {
    
    public weak var player: VCPlayer? {
        didSet {
            playerView.player = player
        }
    }
    
    private lazy var playerView: SSPlayerView = {
        let playerView = SSPlayerView(player: player)
        return playerView
    }()
    
    internal lazy var renderView: UIView = {
        let view = UIView()
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
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        playerView.player = nil
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if let _player = self.player {
            let rect = AVMakeRect(aspectRatio: _player.videoDescription.renderSize, insideRect: self.bounds)
            guard rect.origin.x.isNaN == false,
                  rect.origin.y.isNaN == false,
                  rect.size.width.isNaN == false,
                  rect.size.height.isNaN == false
            else {
                return
            }
            playerView.frame = rect
            renderView.frame = rect
        }
    }
    
    public func draw(images: [String : CIImage], blackImage: CIImage, renderSize: CGSize, renderScale: CGFloat) -> CIImage? {
        var finalFrame: CIImage?
        finalFrame = images.sorted { (lhs, rhs) -> Bool in
            return lhs.value.indexPath > rhs.value.indexPath
        }.reduce(finalFrame) { (result, args: (key: String, value: CIImage)) -> CIImage? in
            return result?.composited(over: args.value) ?? args.value
        }
        finalFrame = finalFrame?.composited(over: blackImage) ?? blackImage
        if let ciImage = finalFrame {
            let cgImage = CIContext.share.createCGImage(ciImage, from: CGRect(origin: .zero, size: renderSize.scaling(renderScale)))
            DispatchQueue.main.async {
                self.renderView.layer.contents = cgImage
            }
        } else {
            DispatchQueue.main.async {
                self.renderView.layer.contents = nil
            }
        }
        return nil
    }
    
}
