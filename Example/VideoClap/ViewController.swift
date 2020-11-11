//
//  ViewController.swift
//  VideoClap
//
//  Created by lai001 on 10/24/2020.
//  Copyright (c) 2020 lai001. All rights reserved.
//

import UIKit
import AVFoundation
import SnapKit
import Photos
import VideoClap
import SDWebImage
import SSPlayer

class ViewController: UIViewController {

    var videoDescription: VCFullVideoDescription {
        return videoClap.requestCallbackHandler.videoDescription as! VCFullVideoDescription
    }
    
    lazy var videoClap: VideoClap = {
        let videoClap = VideoClap()
        return videoClap
    }()
    
    lazy var player: SSPlayer = {
        let player = SSPlayer()
        return player
    }()
    
    lazy var playerView: SSPlayerView = {
        let playerView = SSPlayerView(frame: .zero, player: player)
        return playerView
    }()
    
    lazy var slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
        slider.addTarget(self, action: #selector(durationSliderValueChanged(slider:event:)), for: .valueChanged)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(sliderTapped(gestureRecognizer:)))
        slider.addGestureRecognizer(tapGestureRecognizer)
        slider.addTarget(self, action: #selector(durationSliderValueChanged(slider:event:)), for: .valueChanged)
        return slider
    }()
    
    lazy var playButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.setImage(UIImage(color: .blue, size: CGSize(width: 44, height: 44)), for: .normal)
        button.setImage(UIImage(color: .red, size: CGSize(width: 44, height: 44)), for: .selected)
        button.addTarget(self, action: #selector(playButtonDidTap), for: .touchUpInside)
        return button
    }()
    
    lazy var imageCache: SDImageCache = {
        let cache = SDImageCache()
        cache.config.maxMemoryCost = UInt(Float(ProcessInfo().physicalMemory) * 0.2)
        return cache
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PHPhotoLibrary.requestAuthorization { (_) in
            
        }
        NotificationCenter.default.addObserver(self, selector: #selector(transitionChange), name: TransitionNotification, object: nil)
        setupUI()
        
        videoDescription.fps = 24.0
        videoDescription.renderSize = CGSize(width: 720, height: 720)
        videoDescription.waterMarkRect = .init(normalizeCenter: CGPoint(x: 0.9, y: 0.1), normalizeWidth: 0.1, normalizeHeight: 0.1)
        videoDescription.setWaterMarkImageClosure { () -> CIImage? in
            if let cacheImage = self.imageCache.imageFromMemoryCache(forKey: "waterMarkImage")?.ciImage {
                return cacheImage
            } else {
                let waterMarkImageURL = Bundle.main.url(forResource: "test3", withExtension: "jpg", subdirectory: "Mat")!
                let image = CIImage(contentsOf: waterMarkImageURL)!
                self.imageCache.storeImage(toMemory: UIImage(ciImage: image), forKey: "waterMarkImage")
                return image
            }
        }
        
        do {
            let track = VCMediaTrack(id: "track1",
                                     trackType: .video,
                                     timeRange: CMTimeRange(start: 0.0, duration: 8.0))
            track.mediaURL = Bundle.main.url(forResource: "video0", withExtension: "mp4", subdirectory: "Mat")
            track.mediaClipTimeRange = CMTimeRange(start: 0.0, duration: 8.0)
            track.setFilterLutImageClosure { () -> CIImage? in
                let url = Bundle.main.url(forResource: "lut_filter_27", withExtension: "jpg", subdirectory: "Mat")!
                if let cacheImage = self.imageCache.imageFromMemoryCache(forKey: url.lastPathComponent)?.ciImage {
                    return cacheImage
                } else {
                    let image = CIImage(contentsOf: url)!
                    self.imageCache.storeImage(toMemory: UIImage(ciImage: image), forKey: url.lastPathComponent)
                    return image
                }
            }
            videoDescription.mediaTracks.append(track)
        }
        
        do {
            let track = VCMediaTrack(id: "track2",
                                     trackType: .stillImage,
                                     timeRange: CMTimeRange(start: 0.0, duration: 5.0))
            
            track.imageURL = Bundle.main.url(forResource: "test0", withExtension: "jpg", subdirectory: "Mat")
            track.setImageClosure { () -> CIImage? in
                if let cacheImage = self.imageCache.imageFromMemoryCache(forKey: track.id)?.ciImage {
                    return cacheImage
                } else {
                    let image = CIImage(contentsOf: track.imageURL!)!
                    self.imageCache.storeImage(toMemory: UIImage(ciImage: image), forKey: track.id)
                    return image
                }
            }
            videoDescription.mediaTracks.append(track)
        }
        
        do {
            let track = VCMediaTrack(id: "track3",
                                     trackType: .audio,
                                     timeRange: CMTimeRange(start: 0.0, duration: 180.0))
            track.mediaURL = Bundle.main.url(forResource: "02.Ellis - Clear My Head (Radio Edit) [NCS]", withExtension: "mp3", subdirectory: "Mat")
            track.mediaClipTimeRange = CMTimeRange(start: 10.0, duration: 100.0)
            if #available(iOS 11.0, *) {
                track.audioEffectProvider = VCGhostAudioEffectProvider()
            }
            let desc = VCAudioVolumeRampDescription(startVolume: 0.7,
                                                    endVolume: 1.0,
                                                    timeRange: CMTimeRange(start: 0.0, duration: 10.0))
            track.audioVolumeRampDescriptions = [desc]
            videoClap.videoDescription.mediaTracks.append(track)
        }
        
        do {
            let fadeTrasition = VCModTransition()
            fadeTrasition.fromId = "track2"
            fadeTrasition.toId = "track1"
            fadeTrasition.timeRange = CMTimeRange(start: 0.0, end: 5.0)
            videoDescription.transitions.append(fadeTrasition)
        }
        
//        do {
//            let trajectory = VCMovementTrajectory()
//            trajectory.id = "track1"
//            trajectory.timeRange = CMTimeRange(start: CMTime(seconds: 2), end: CMTime(seconds: 30))
//            videoDescription.trajectories.append(trajectory)
//        }
        
        do {
            let lamination = VCLamination(id: "lamination1")
            lamination.timeRange = CMTimeRange(start: .zero, end: videoClap.estimateVideoDuration())
            lamination.setImageClosure { () -> CIImage? in
                if let cacheImage = self.imageCache.imageFromMemoryCache(forKey: lamination.id)?.ciImage {
                    return cacheImage
                } else {
                    let imageUrl = Bundle.main.url(forResource: "Anniversary1", withExtension: "png", subdirectory: "Mat")!
                    let image = CIImage(contentsOf: imageUrl)!
                    self.imageCache.storeImage(toMemory: UIImage(ciImage: image), forKey: lamination.id)
                    return image
                }
            }
            videoDescription.laminations = [lamination]
        }
        
        do {
            let animationSticker = VCAnimationSticker()
            animationSticker.id = "animationSticker1"
            animationSticker.rect = VCRect(normalizeCenter: CGPoint(x: 0.25, y: 0.2), normalizeSize: CGSize(width: 0.35, height: 0.35))
            animationSticker.timeRange = CMTimeRange(start: .zero, duration: videoClap.estimateVideoDuration())
            animationSticker.setAnimationView("Watermelon", subdirectory: "Mat/LottieAnimations")
            animationSticker.animationView?.frame = CGRect(origin: .zero, size: CGSize(width: 200, height: 200))
            videoDescription.animationStickers = [animationSticker]
        }
        
//        let reverseVideo = VCReverseVideo()
//        reverseVideo.exportUrl = FileManager.default.temporaryDirectory.appendingPathComponent("tmp.mp4")
//        reverseVideo.inputUrl = Bundle.main.url(forResource: "video1", withExtension: "mp4", subdirectory: "Mat")
//        LLog(reverseVideo.exportUrl)
//        do {
//            try reverseVideo.prepare()
//            try reverseVideo.start()
//        } catch let error {
//            LLog(error)
//        }
        
//        initPlay()
//        export(fileName: nil) { }
        
//        allCasesExportVideo()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        imageCache.clearMemory()
    }
    
    func getTransition(type: TransitionType) -> VCTransitionProtocol {
        let transition: VCTransitionProtocol
        switch type {
        case .Alpha:
            transition = VCAlphaTransition()
        case .BarsSwipe:
            transition = VCBarsSwipeTransition()
        case .Blur:
            transition = VCBlurTransition()
        case .CopyMachine:
            transition = VCCopyMachineTransition()
        case .Dissolve:
            transition = VCDissolveTransition()
        case .Flip:
            transition = VCFlipTransition()
        case .IceMelting:
            transition = VCIceMeltingTransition()
        case .Slide:
            transition = VCSlideTransition()
        case .Swirl:
            transition = VCSwirlTransition()
        case .Vortex:
            transition = VCVortexTransition()
        case .Wave:
            transition = VCWaveTransition()
        case .Wipe:
            transition = VCWipeTransition()
        case .Windowslice:
            transition = VCWindowsliceTransition()
        case .PageCurl:
            transition = VCPageCurlWithShadowTransition()
        case .Doorway:
            transition = VCDoorwayTransition()
        case .Squareswire:
            transition = VCSquareswireTransition()
        case .Mod:
            transition = VCModTransition()
        case .Cube:
            transition = VCCubeTransition()
        case .Translation:
            transition = VCTranslationTransition().config(closure: {
                $0.translation = 720.0
            })
        }
        return transition
    }
    
    func allCasesExportVideo() {
        DispatchQueue(label: "allCasesExportVideo").async {
            let group = DispatchGroup()
            for type in TransitionType.allCases {
                group.enter()
                let transition: VCTransitionProtocol = self.getTransition(type: type)
                transition.fromId = "track2"
                transition.toId = "track1"
                transition.timeRange = CMTimeRange(start: 0.0, end: 5.0)
                self.videoDescription.transitions = [transition]
                self.export(fileName: type.rawValue + ".mov") {
                    group.leave()
                }
                group.wait()
            }
        }
    }
    
    @objc func transitionChange(_ sender: Notification) {
        let type = sender.userInfo?["transitionType"] as! TransitionType
        let trasition: VCTransitionProtocol = getTransition(type: type)
        trasition.fromId = "track2"
        trasition.toId = "track1"
        trasition.timeRange = CMTimeRange(start: 0.0, end: 5.0)
        videoDescription.transitions = [trasition]
        initPlay()
//        export(fileName: nil) { }
    }
    
    func initPlay() {
        player.currentItem?.cancelPendingSeeks()
        player.pause()
        let item = videoClap.playerItemForPlay()
        player.replaceCurrentItem(with: item)
        playButton.isSelected = true
        
        player.observePlayingTime { (time: CMTime) in
            self.timer()
        }
        
        player.play()
    }
    
    func export(fileName: String?, completion: @escaping () -> Void) {
        videoClap.exportToVideo(fileName: fileName) { (progress) in
            print(progress.fractionCompleted)
        } completionHandler: { (url, error) in
            #if targetEnvironment(simulator)
            
            if let url = url {
                do {
                    let folder = "/Users/laimincong/Desktop/Temp/Videos/" // replace your folder path
                    if FileManager.default.fileExists(atPath: folder) == false {
                        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true, attributes: nil)
                    }
                    let target: String = folder + url.lastPathComponent
                    if FileManager.default.fileExists(atPath: target) {
                        try FileManager.default.removeItem(atPath: target)
                    }
                    try FileManager.default.copyItem(atPath: url.path, toPath: target)
                } catch let error {
                    LLog(error)
                }
            }
            completion()
            #else
            
            if let url = url {
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                } completionHandler: { _, _ in
                    completion()
                }
            } else {
                completion()
            }
            
            #endif
        }
    }
    
    @objc func durationSliderValueChanged(slider: UISlider, event: UIEvent) {
        
        struct Scope {
            static var cacheIsPlaying = false
        }
        
        guard let touch = event.allTouches?.first else { return }
        
        switch touch.phase {
        case .began:
            Scope.cacheIsPlaying = player.isPlaying
            player.removePlayingTimeObserver()
            player.pause()
            
        case .ended:
            if Scope.cacheIsPlaying {
                player.observePlayingTime { (time: CMTime) in
                    self.timer()
                }
                player.play()
            }
            
        case .moved:
            let time = CMTime(seconds: (player.currentItem?.duration.seconds ?? 0) * Double(slider.value))
            player.seekSmoothly(to: time) {
                self.timer()
            }
            
        default:
            break
        }
    }
    
    @objc func sliderTapped(gestureRecognizer: UIGestureRecognizer) {
        let pointTapped: CGPoint = gestureRecognizer.location(in: self.slider)
        let positionOfSlider: CGPoint = slider.frame.origin
        let widthOfSlider: CGFloat = slider.frame.size.width
        let newValue = ((pointTapped.x - positionOfSlider.x) * CGFloat(slider.maximumValue) / widthOfSlider)
        let cacheIsPlaying = player.isPlaying
        let duration = player.currentItem?.duration.seconds ?? 1
        let time = CMTime(seconds: Double(newValue) * duration)
        
        player.seekSmoothly(to: time) { [unowned self] in
            self.timer()
            if cacheIsPlaying {
                self.player.play()
            } else {
                self.player.pause()
            }
        }
    }
    
    @objc func timer() {
        let currentTime = player.currentItem?.currentTime().seconds ?? 0
        let duration = player.currentItem?.duration.seconds ?? 1
        slider.value = Float(currentTime / duration)
        playButton.isSelected = player.isPlaying
    }
    
    @objc func playButtonDidTap(_ sender: UIButton) {
        if player.isPlaying {
            player.pause()
            playButton.isSelected = false
        } else {
            player.play()
            playButton.isSelected = true
        }
    }

}

extension ViewController {
    
    func setupUI() {
        view.addSubview(playerView)
        view.addSubview(slider)
        view.addSubview(playButton)
        playerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        slider.snp.makeConstraints { (make) in
            make.height.equalTo(44)
            make.bottom.equalToSuperview().offset(-30)
            make.left.right.equalToSuperview().inset(20)
        }
        playButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(slider.snp.top).offset(-20)
            make.size.equalTo(44)
            make.left.equalToSuperview().offset(20)
        }
    }
    
}
