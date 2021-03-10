//
//  VCPlayerContainerView.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/23.
//

import SSPlayer
import AVFoundation

public enum RenderApi {
    case opengles
    case metal
}

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
    
    internal lazy var renderView: MetalImageView = {
        let view = MetalImageView()
        return view
    }()
    
    lazy var glkView: GLImageView = {
        let view = GLImageView(frame: .zero)
        return view
    }()
    
    public internal(set) var renderApi: RenderApi = .opengles
    
    internal var isMetalAvailable: Bool = MetalDevice.share.device != nil
    
    public override var backgroundColor: UIColor? {
        didSet {
            playerView.backgroundColor = backgroundColor
            renderView.backgroundColor = backgroundColor
        }
    }
    
    public convenience init(player: VCPlayer? = nil, renderApi: RenderApi = .opengles) {
        self.init(frame: .zero, player: player, renderApi: renderApi)
    }
    
    public init(frame: CGRect, player: VCPlayer? = nil, renderApi: RenderApi = .opengles) {
        self.player = player
        super.init(frame: frame)
        _ = playerView
        if isMetalAvailable == false {
            self.renderApi = .opengles
        } else {
            self.renderApi = renderApi
        }
        
        switch self.renderApi {
        case .opengles:
            addSubview(glkView)
        case .metal:
            addSubview(renderView)
        }
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
            renderView.frame = rect
            glkView.frame = rect
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
        if var ciImage = finalFrame {
            ciImage = ciImage.cropped(to: CGRect(origin: .zero, size: renderSize.scaling(renderScale)))
            switch renderApi {
            case .opengles:
                glkView.image = ciImage
            case .metal:
                renderView.image = ciImage
                renderView.redraw()
            }
        }
        return nil
    }
    
}
