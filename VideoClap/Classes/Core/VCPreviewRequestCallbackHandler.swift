//
//  VCPreviewRequestCallbackHandler.swift
//  VideoClap
//
//  Created by laimincong on 2020/12/7.
//

import AVFoundation
import SSPlayer
import Lottie
import SnapKit

open class VCPreviewRequestCallbackHandler: VCRequestCallbackHandler {
    
    private lazy var ciContext: CIContext = {
        if let gpu = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: gpu)
        }
        if let eaglContext = EAGLContext(api: .openGLES3) ?? EAGLContext(api: .openGLES2) {
            return CIContext(eaglContext: eaglContext)
        }
        return CIContext()
    }()
    
    internal var lottieTrackEnumor: [String : VCLottieTrackDescription] = [:]
    
    public lazy var player: SSPlayer = {
        let player = SSPlayer()
        return player
    }()
    
    private lazy var placeLayer: AVPlayerLayer = {
        let placeLayer = AVPlayerLayer(player: self.player)
        return placeLayer
    }()
    
    lazy var renderView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.backgroundColor = .black
        return view
    }()
    
//    public lazy var playerView: SSPlayerView = {
//        let playerView = SSPlayerView(frame: .zero, player: player)
//        playerView.clipsToBounds = true
//        return playerView
//    }()
    
    public lazy var containerView: UIView = {
        let view = UIView()
        return view
    }()
    
    public lazy var lottiePreviewDic: [String : VCLottiePreview] = {
        return [:]
    }()

    public var stopRenderFlag: Bool = false
    
    public override func contextChanged() {
        super.contextChanged()
        _ = placeLayer
        
        let trackBundle = videoDescription.trackBundle
        lottieTrackEnumor = trackBundle.lottieTracks.reduce([:]) { (result, track) in
            var mutable = result
            mutable[track.id] = track
            return mutable
        }
        
        containerView.addSubview(renderView)
        
        renderView.snp.remakeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(videoDescription.renderSize)
        }
        
        do {
            lottiePreviewDic.forEach({ $0.value.removeFromSuperview() })
            lottiePreviewDic = [:]
            for lottieTrack in trackBundle.lottieTracks {
                let preview = VCLottiePreview()
                renderView.addSubview(preview)
                preview.setup(lottieTrack: lottieTrack, renderSize: videoDescription.renderSize)
                lottiePreviewDic[lottieTrack.id] = preview
            }
        }
        
    }
    
    public override func handle(item: VCRequestItem, compositionTime: CMTime, blackImage: CIImage, finish: (CIImage?) -> Void) {
        self.compositionTime = compositionTime
        if stopRenderFlag {
            finish(nil)
            return
        }
        self.item = item
        self.blackImage = blackImage
        self.instruction = item.instruction
//        print("compositionTime: ", compositionTime.seconds)
        preprocessFinishedImages.removeAll()
        var finalFrame: CIImage?
        
        preprocess()
        
        let transionImage = processTransions()
//        let laminationImage = processLamination()
//        let lottieImage = processLottie()
//        let textImage = processText()
        
        for (id, lottiePreview) in lottiePreviewDic {
            DispatchQueue.main.async {
                if let track = item.instruction.trackBundle.lottieTracks.first(where: { $0.id == id }),
                   let view = track.animationView,
                   let animation = view.animation
                {
                    let animationPlayTime = compositionTime - track.timeRange.start
                    let progress = CGFloat(animationPlayTime.seconds.truncatingRemainder(dividingBy: animation.duration)).map(from: 0...CGFloat(animation.duration), to: 0...1)
                    view.currentProgress = progress
                    lottiePreview.isHidden = false
                } else {
                    lottiePreview.isHidden = true
                }
            }
        }
        
        if let transionImage = transionImage {
            finalFrame = transionImage
        } else {
            finalFrame = preprocessFinishedImages.reduce(finalFrame) { (result, args: (key: String, value: CIImage)) -> CIImage? in
                return result?.composited(over: args.value) ?? args.value
            }
        }
        
        if let ciImage = finalFrame {
            let cgImage = ciContext.createCGImage(ciImage, from: CGRect(origin: .zero, size: self.videoDescription.renderSize))
            DispatchQueue.main.async {
                self.renderView.layer.contents = cgImage
            }
        }

        finish(nil)
    }
    
}
