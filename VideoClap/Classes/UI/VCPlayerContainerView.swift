//
//  VCPlayerContainerView.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/23.
//

import SSPlayer
import AVFoundation

open class VCPlayerContainerView: UIView, VCRenderTarget {
    
    public weak var player: VCPlayer? {
        didSet {
            playerView.player = player
        }
    }
    
    private lazy var playerView: SSPlayerView = {
        let playerView = SSPlayerView(player: player)
        return playerView
    }()
    
    public convenience init(player: VCPlayer? = nil) {
        self.init(frame: .zero, player: player)
    }
    
    public init(frame: CGRect, player: VCPlayer? = nil) {
        self.player = player
        super.init(frame: frame)
        addSubview(playerView)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        playerView.player = nil
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        playerView.frame = fitRect()
    }
    
    public func fitRect() -> CGRect {
        if let _player = self.player {
            let rect = AVMakeRect(aspectRatio: _player.videoDescription.renderSize, insideRect: self.bounds)
            guard rect.origin.x.isNaN == false,
                  rect.origin.y.isNaN == false,
                  rect.size.width.isNaN == false,
                  rect.size.height.isNaN == false
            else {
                return .zero
            }
            return rect
        }
        return .zero
    }
    
    public func draw(compositionTime: CMTime, images: [String : CIImage], blackImage: CIImage, renderSize: CGSize, renderScale: CGFloat) -> CIImage? {
        var finalFrame: CIImage?
        finalFrame = images.sorted { (lhs, rhs) -> Bool in
            return lhs.value.indexPath > rhs.value.indexPath
        }.reduce(finalFrame) { (result, args: (key: String, value: CIImage)) -> CIImage? in
            return result?.composited(over: args.value) ?? args.value
        }
        finalFrame = finalFrame?.composited(over: blackImage) ?? blackImage
        if var ciImage = finalFrame {
            ciImage = ciImage.cropped(to: CGRect(origin: .zero, size: renderSize.scaling(renderScale)))
            return ciImage
        }
        return nil
    }
    
}

open class VCOpenglPlayerContainerView: VCPlayerContainerView {
    
    lazy var glkView: GLImageView = {
        let view = GLImageView(frame: .zero)
        return view
    }()
    
    public override init(frame: CGRect, player: VCPlayer? = nil) {
        super.init(frame: frame, player: player)
        addSubview(glkView)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        glkView.frame = fitRect()
    }
    
    public override func draw(compositionTime: CMTime, images: [String : CIImage], blackImage: CIImage, renderSize: CGSize, renderScale: CGFloat) -> CIImage? {
        guard let ciImage = super.draw(compositionTime: compositionTime, images: images, blackImage: blackImage, renderSize: renderSize, renderScale: renderScale) else {
            return nil
        }
        glkView.image = ciImage
        return nil
    }
    
}

open class VCMetalPlayerContainerView: VCPlayerContainerView {
    
    internal lazy var renderView: MetalImageView = {
        let view = MetalImageView()
        return view
    }()
    
    public override init(frame: CGRect, player: VCPlayer? = nil) {
        super.init(frame: frame, player: player)
        addSubview(renderView)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        renderView.frame = fitRect()
    }
    
    public override func draw(compositionTime: CMTime, images: [String : CIImage], blackImage: CIImage, renderSize: CGSize, renderScale: CGFloat) -> CIImage? {
        guard let ciImage = super.draw(compositionTime: compositionTime, images: images, blackImage: blackImage, renderSize: renderSize, renderScale: renderScale) else {
            return nil
        }
        renderView.image = ciImage
        renderView.redraw()
        return nil
    }
    
}

open class VCSampleBufferDisplayPlayerContainerView: VCPlayerContainerView {
    
    lazy var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer = {
        let layer = AVSampleBufferDisplayLayer()
        layer.videoGravity = .resizeAspect
        layer.isOpaque = true
        return layer
    }()
    
    lazy var context: CIContext = {
        var context: CIContext
        if #available(iOS 13.0, *), let queue = MetalDevice.share.commandQueue {
            context = CIContext(mtlCommandQueue: queue)
        } else if let device = MetalDevice.share.device {
            context = CIContext(mtlDevice: device)
        } else {
            context = CIContext.share
        }
        return context
    }()
    
    var buffer: CVPixelBuffer?
    
    public override init(frame: CGRect, player: VCPlayer? = nil) {
        super.init(frame: frame, player: player)
        layer.addSublayer(sampleBufferDisplayLayer)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        sampleBufferDisplayLayer.frame = fitRect()
        if let _player = self.player {
            let size = _player.videoDescription.renderSize.scaling(_player.videoDescription.renderScale)
            CVPixelBufferCreate(nil, Int(size.width), Int(size.height),
                                kCVPixelFormatType_32BGRA,
                                [kCVPixelBufferIOSurfacePropertiesKey:[:]] as CFDictionary,
                                &buffer)
        }
    }
    
    public override func draw(compositionTime: CMTime, images: [String : CIImage], blackImage: CIImage, renderSize: CGSize, renderScale: CGFloat) -> CIImage? {
        guard let ciImage = super.draw(compositionTime: compositionTime, images: images, blackImage: blackImage, renderSize: renderSize, renderScale: renderScale) else {
            return nil
        }
        guard let buffer = self.buffer else { return nil }
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0));
        context.render(ciImage, to: buffer, bounds: ciImage.extent, colorSpace: CGColorSpaceCreateDeviceRGB())
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0));
        var samplfeBuffer: CMSampleBuffer?
        var des: CMVideoFormatDescription?
        var info = CMSampleTimingInfo()
        info.presentationTimeStamp = compositionTime
        info.duration = CMTime(seconds: 1.0 / (self.player?.videoDescription.fps ?? 24.0), preferredTimescale: 600)
        info.decodeTimeStamp = compositionTime

        CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil,
                                                     imageBuffer: buffer,
                                                     formatDescriptionOut: &des)
        if let des = des {
            CMSampleBufferCreateReadyWithImageBuffer(allocator: nil,
                                                     imageBuffer: buffer,
                                                     formatDescription: des,
                                                     sampleTiming: &info,
                                                     sampleBufferOut: &samplfeBuffer)
        }
        if let samplfeBuffer = samplfeBuffer {
            sampleBufferDisplayLayer.enqueue(samplfeBuffer)
        }
        return nil
    }
    
}
