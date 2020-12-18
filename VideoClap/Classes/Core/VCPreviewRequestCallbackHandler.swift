//
//  VCPreviewRequestCallbackHandler.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/7.
//

import AVFoundation
import SSPlayer
import Lottie
import SnapKit

open class VCPreviewRequestCallbackHandler: VCRequestCallbackHandler {

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
    
    lazy var laminationImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        return imageView
    }()
    
    public lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    public lazy var lottiePreviewDic: [String : VCLottiePreview] = {
        return [:]
    }()

    public var stopRenderFlag: Bool = false
    
    public func rebuildPlayer(item: AVPlayerItem) {
        let newItem = item
        player = SSPlayer(playerItem: newItem)
        placeLayer.player = player
    }
    
    public func removePlayerItem() {
        player.currentItem?.cancelPendingSeeks()
        player.cancelPendingPrerolls()
        player.replaceCurrentItem(with: nil)
        player = SSPlayer()
        placeLayer.player = player
    }
    
    public override func contextChanged() {
        super.contextChanged()
        _ = placeLayer
        
        let trackBundle = videoDescription.trackBundle
        lottieTrackEnumor = trackBundle.lottieTracks.reduce([:]) { (result, track) in
            var mutable = result
            if let animationView = track.animationView {
                let scle = CGFloat(videoDescription.renderScale)
                animationView.frame.size = CGSize(width: 100, height: 100).applying(.init(scaleX: scle, y: scle))
            }
            mutable[track.id] = track
            return mutable
        }
        
        containerView.addSubview(renderView)
        
        renderView.snp.remakeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(videoDescription.renderSize)
        }
        
        do {
            for lottieTrack in trackBundle.lottieTracks {
                if let _ = lottiePreviewDic[lottieTrack.id] {
                    
                } else {
                    let preview = VCLottiePreview()
                    renderView.addSubview(preview)
                    preview.setup(lottieTrack: lottieTrack, renderSize: videoDescription.renderSize)
                    lottiePreviewDic[lottieTrack.id] = preview
                }
            }
        }
        
        renderView.addSubview(laminationImageView)
        
        laminationImageView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
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
        let laminationImage = processLamination()
//        let lottieImage = processLottie()
//        let textImage = processText()
        
        for (id, lottiePreview) in lottiePreviewDic {
            if let track = item.instruction.trackBundle.lottieTracks.first(where: { $0.id == id }) {
                let animationPlayTime = compositionTime - track.timeRange.start
                track.animationPlayTime = animationPlayTime
                track.animationFrame { (image: CIImage?) in
                    if let image = image {
                        DispatchQueue.main.async {
                            lottiePreview.imageView.image = UIImage(ciImage: image)
                            lottiePreview.isHidden = false
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
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
        } else {
            DispatchQueue.main.async {
                self.renderView.layer.contents = nil
            }
        }
        
        if let laminationImage = laminationImage {
            let image = UIImage(ciImage: laminationImage)
            DispatchQueue.main.async {
                self.laminationImageView.isHidden = false
                self.laminationImageView.image = image
            }
        } else {
            DispatchQueue.main.async {
                self.laminationImageView.isHidden = true
            }
        }

        finish(nil)
    }
    
}
