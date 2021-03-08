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
import SSPlayer
import MobileCoreServices

class NavigationController: UINavigationController {
    
}

class ViewController: UIViewController {

    var videoDescription: VCVideoDescription {
        return player.videoDescription
    }
    
    var player: VCPlayer {
        return vcplayer
    }
    
    var trackBundle: VCTrackBundle {
        return videoDescription.trackBundle
    }
    
    public lazy var containerView: VCPlayerContainerView = {
        let view = VCPlayerContainerView(player: vcplayer)
        return view
    }()
    
    lazy var vcplayer: VCPlayer = {
        let player = VCPlayer()
        return player
    }()
    
    var exportVideoClap = VideoClap()
    
    lazy var slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
//        slider.addTarget(self, action: #selector(durationSliderValueChanged(slider:event:)), for: .valueChanged)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(sliderTapped(gestureRecognizer:)))
        slider.addGestureRecognizer(tapGestureRecognizer)
        slider.addTarget(self, action: #selector(durationSliderValueChanged(slider:event:)), for: .valueChanged)
        return slider
    }()
    
    lazy var timelabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        return label
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
    
    lazy var exportButton: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "导出", style: .plain, target: self, action: #selector(exportButtonDidTap))
        return item
    }()
    
    lazy var addButton: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "添加", style: .plain, target: self, action: #selector(addButtonDidTap))
        return item
    }()
    
    let ratio: CGFloat = 9.0 / 16.0
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: TransitionNotification, object: nil)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        player.realTimeRenderTarget = self.containerView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        VideoClap.cleanExportFolder()
        
        NotificationCenter.default.addObserver(self, selector: #selector(transitionChange), name: TransitionNotification, object: nil)
        setupUI()
        videoDescription.fps = 24.0
        videoDescription.renderScale = UIScreen.main.scale
        videoDescription.renderSize = CGSize(width: view.bounds.width * ratio, height: view.bounds.width)

        do {
            let track = VCImageTrackDescription()
            track.id = "waterMarkTrack"
            track.indexPath = IndexPath(item: 0, section: 1000)
            track.timeRange = CMTimeRange(start: 0.0, duration: 5.0)
            track.mediaURL = resourceURL(filename: "test3.jpg")
            track.imageLayout = .rect(.init(center: CGPoint(x: 0.9, y: 0.1), width: 0.1, height: 0.1))
            trackBundle.imageTracks.append(track)
        }
        
        do {
            let trajectory = VCMovementTrajectory()
            trajectory.movementRatio = 0.1
            let track = VCVideoTrackDescription()
            track.indexPath = IndexPath(item: 0, section: 900)
            if let url = resourceURL(filename: "test1.jpg") {
                track.canvasStyle = .image(url)
            }
            track.trajectory = trajectory
            track.id = "videoTrack"
            let source = CMTimeRange(start: 5.0, duration: 1)
            let target = CMTimeRange(start: 5.0, end: 6.0)
            track.timeMapping = CMTimeMapping(source: source, target: target)
            track.mediaURL = resourceURL(filename: "video0.mp4")
            track.lutImageURL = resourceURL(filename: "lut_filter_27.jpg")
            trackBundle.videoTracks.append(track)
        }
        
        do {
//            let trajectory = VCMovementTrajectory()
//            trajectory.movementRatio = 0.1
            let track = VCVideoTrackDescription()
            track.indexPath = IndexPath(item: 0, section: 900)
            track.canvasStyle = .blur
//            track.trajectory = trajectory
            track.id = "videoTrack1"
            let source = CMTimeRange(start: 5.0, duration: 4)
            let target = CMTimeRange(start: 6, end: 10.0)
            track.timeMapping = CMTimeMapping(source: source, target: target)
            track.mediaURL = resourceURL(filename: "video0.mp4")
//            track.lutImageURL = resourceURL(filename: "lut_filter_27.jpg")
            trackBundle.videoTracks.append(track)
        }
        
        do {
            let trajectory = VCMovementTrajectory()
            trajectory.movementRatio = 0.1
            let track = VCImageTrackDescription()
            track.indexPath = IndexPath(item: 1, section: 900)
            if let url = resourceURL(filename: "test4.jpg") {
                track.canvasStyle = .image(url)
            }
            track.trajectory = trajectory
            track.id = "imageTrack"
            track.timeRange = CMTimeRange(start: 0.0, duration: 5.0)
            track.mediaURL = resourceURL(filename: "test3.jpg")
//            track.cropedRect = CGRect(x: 0.5, y: 0.2, width: 0.5, height: 0.5)
            trackBundle.imageTracks.append(track)
        }
        
        do {
            let track = VCAudioTrackDescription()
            track.id = "audioTrack"
            let source = CMTimeRange(start: 0, end: 10.0)
            let target = CMTimeRange(start: 0, end: 10.0)
            track.timeMapping = CMTimeMapping(source: source, target: target)
            track.mediaURL = resourceURL(filename: "02.Ellis - Clear My Head (Radio Edit) [NCS].mp3")
            if #available(iOS 11.0, *) {
                track.audioEffectProvider = VCChildrenAudioEffectProvider()
            } else {
                track.audioEffectProvider = VCChildrenAudioEffectProvider2()
            }
            let desc = VCAudioVolumeRampDescription(startVolume: 0.0,
                                                    endVolume: 1.0,
                                                    timeRange: CMTimeRange(start: 0.0, duration: 10.0))
            track.audioVolumeRampDescriptions = [desc]
            trackBundle.audioTracks.append(track)
        }
        
        do {
            let trasition = VCTransition()
            trasition.transition = VCCubeTransition()
            addTransition(trasition)
        }
        
        do {
            let lamination = VCLaminationTrackDescription()
            lamination.indexPath = IndexPath(item: 1, section: 999)
            lamination.id = "laminationTrack"
            lamination.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: 10))
            lamination.mediaURL = resourceURL(filename: "Anniversary1.png")
            trackBundle.imageTracks.append(lamination)
        }
        
        do {
            for index in 0..<2 {
                let animationSticker = VCLottieTrackDescription()
                animationSticker.indexPath = IndexPath(item: index, section: 901)
                animationSticker.id = "animationSticker\(index)"
                let size: CGSize = CGSize(width: 0.35 / ratio, height: 0.35)
                animationSticker.rect = VCRect(center: CGPoint(x: CGFloat.random(in: 0.0...1.0), y: CGFloat.random(in: 0.0...1.0)),
                                               size: size)
                animationSticker.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: 10))
                animationSticker.mediaURL = resourceURL(filename: "Watermelon.json")
                trackBundle.imageTracks.append(animationSticker)
            }
        }
        
        do {
            let textTrack = VCTextTrackDescription()
            textTrack.indexPath = IndexPath(item: 0, section: 902)
            textTrack.id = "textTrack"
            textTrack.imageLayout = .center(CGPoint(x: 0.5, y: 0.5))
            textTrack.timeRange = CMTimeRange(start: 0.0, end: 10.0)
            textTrack.textEffectProvider = VCRotationTextEffect(rotationType: .rotate(25.0))
//            textTrack.rotateRadian = .pi * 0.15
            textTrack.text = AttributedStringBuilder(text: "按键或把手把字和符号打印在纸上的机械，有手打和电打两种。\n在大多数办公室，电脑已经取代了打字机。\n她拿起一张纸，把它哗哗啦啦地塞到打字机中。")
//                .addAttributes(value: [.foregroundColor : UIColor.clear, .font : UIFont.systemFont(ofSize: 90, weight: .bold), .strokeWidth: -3.0, .strokeColor: UIColor.blue])
                .addAttributes(value: [.foregroundColor : UIColor.red, .font : UIFont.systemFont(ofSize: 40, weight: .bold)])
                .build()
            trackBundle.imageTracks.append(textTrack)
        }
        
        do {
            let gifTrack = VCGIFTrackDescription()
            gifTrack.indexPath = IndexPath(item: 0, section: 1001)
            let rect = VCRect(x: 0.5, y: 0.5, width: .random(in: 0..<1.0), height: .random(in: 0..<1.0))
            gifTrack.imageLayout = .rect(rect)
            gifTrack.id = "gifTrack"
            gifTrack.timeRange = CMTimeRange(start: 0.0, end: 30.0)
            gifTrack.mediaURL = resourceURL(filename: "d6943138af1.gif")
            trackBundle.imageTracks.append(gifTrack)
        }
        
        initPlay()
//        export(fileName: nil) { }
        
//        allCasesExportVideo()
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
            let v = VCVortexTransition()
            v.type = .single
            transition = v
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
                $0.translationType = .left
                $0.translation = self.videoDescription.renderSize.width
            })
        case .Heart:
            transition = VCHeartTransition()
        case .Noise:
            transition = VCNoiseTransition()
        case .Megapolis:
            transition = VCMegapolis2DPatternTransition()
        case .Spread:
            transition = VCSpreadTransition()
        case .Bounce:
            transition = VCBounceTransition()
        }
        return transition
    }
    
    func allCasesExportVideo() {
        DispatchQueue(label: "allCasesExportVideo").async {
            let group = DispatchGroup()
            for type in TransitionType.allCases {
                group.enter()
                let transition = VCTransition()
                transition.transition = self.getTransition(type: type)
                self.addTransition(transition)
                self.export(fileName: type.rawValue + ".mov") {
                    group.leave()
                }
                group.wait()
            }
        }
    }
    
    @objc func transitionChange(_ sender: Notification) {
        let type = sender.userInfo?["transitionType"] as! TransitionType
        videoDescription.transitions.first.unsafelyUnwrapped.transition = getTransition(type: type)
        vcplayer.reloadFrame()
    }
    
    func addTransition(_ trasition: VCTransition) {
        trasition.fromTrack = videoDescription.trackBundle.imageTracks.first(where: { $0.id == "imageTrack" })
        trasition.toTrack = videoDescription.trackBundle.videoTracks.first(where: { $0.id == "videoTrack" })
        trasition.range = VCRange(left: 0.5, right: 0.5)
        videoDescription.transitions = [trasition]
    }
    
    func initPlay() {
        vcplayer.reload()
        playButton.isSelected = true
        
        player.observePlayingTime { [weak self] (time: CMTime) in
            guard let self = self else { return }
            self.timer()
        }
        
        player.play()
    }
    
    func export(fileName: String?, completion: @escaping () -> Void) {
        exportVideoClap.videoDescription = self.videoDescription.mutableCopy() as! VCVideoDescription
        exportVideoClap.videoDescription.renderSize = KResolution1920x1080
        exportVideoClap.videoDescription.renderScale = 1.0
        
        exportVideoClap.export { (progress) in
            print(progress.fractionCompleted, fileName ?? "")
        } completionHandler: { (url, error) in
            if let error = error {
                LLog(error)
            }
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
                player.observePlayingTime { [weak self] (time: CMTime) in
                    guard let self = self else { return }
                    self.timer()
                }
                player.play()
            }
            
        case .moved:
            let duration = player.currentItem?.asset.duration ?? CMTime(seconds: 1.0)
            let time = CMTime(seconds: duration.seconds * Double(slider.value))
            player.seekSmoothly(to: time) { [weak self] _ in
                guard let self = self else { return }
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
        
        player.seekSmoothly(to: time) { [weak self] _ in
            guard let self = self else { return }
            self.timer()
            if cacheIsPlaying {
                self.player.play()
            } else {
                self.player.pause()
            }
        }
    }
    
    @objc func timer() {
        let currentTime: CMTime = player.currentItem?.currentTime() ?? .zero
        let duration = player.currentItem?.duration ?? CMTime(seconds: 1.0)
        let value = Float(currentTime.seconds / duration.seconds)
        let isSelected = player.isPlaying
        let nf = NumberFormatter()
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 2
        nf.minimumIntegerDigits = 1
        let timelabelText = nf.string(from: NSNumber(value: currentTime.seconds))! + " / " + nf.string(from: NSNumber(value: duration.seconds))!
        
        if currentTime >= duration {
            player.pause()
            DispatchQueue.main.async {
                self.playButton.isSelected = false
            }
        }
        
        DispatchQueue.main.async {
            self.timelabel.text = timelabelText
            self.playButton.isSelected = isSelected
            self.slider.value = value
        }
    }
    
    @objc func playButtonDidTap(_ sender: UIButton) {
        if player.isPlaying {
            player.pause()
            playButton.isSelected = false
        } else {
            player.play()
            playButton.isSelected = true
            player.observePlayingTime { [weak self] (time: CMTime) in
                guard let self = self else { return }
                self.timer()
            }
        }
    }
    
    @objc func exportButtonDidTap(_ sender: UIBarButtonItem) {
        do {
            try self.vcplayer.enableManualRenderingMode()
            _ = self.vcplayer.export(size: KResolution720x1280) { (progress) in
                LLog(progress.fractionCompleted)
            } completionHandler: { [weak self] (url, error) in
                guard let self = self else { return }
                self.vcplayer.disableManualRenderingMode()
                if let url = url {
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    } completionHandler: { _, _ in
                        LLog("finish ")
                    }
                } else if let error = error {
                    LLog(error)
                }
            }
            playButton.isSelected = false
        } catch let error {
            LLog(error)
        }
    }
    
    @objc func addButtonDidTap(_ sender: UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) ?? []
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
}

extension ViewController {
    
    func setupNavBar() {
        navigationItem.rightBarButtonItems = [exportButton, addButton]
    }
    
    func setupUI() {
        setupNavBar()
        edgesForExtendedLayout = []
        view.backgroundColor = .white
        view.addSubview(containerView)
        view.addSubview(slider)
        view.addSubview(playButton)
        view.addSubview(timelabel)
        containerView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(2)
            make.left.right.equalToSuperview()
            make.height.equalTo(containerView.snp.width)
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
        timelabel.snp.makeConstraints { (make) in
            make.left.equalTo(playButton.snp.right).offset(10)
            make.centerY.equalTo(playButton)
        }
    }
    
}

extension ViewController: (UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if #available(iOS 11.0, *) {
            let type = (info[UIImagePickerController.InfoKey.mediaType] as? String ?? "") as CFString
            switch type {
            case kUTTypeMovie, kUTTypeVideo:
                if let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
                    let asset = AVAsset(url: url)
                    let tracks = self.trackBundle.imageTracks + self.trackBundle.videoTracks
                    let start = tracks.max { (lhs, rhs) -> Bool in
                        return lhs.timeRange.end < rhs.timeRange.end
                    }?.timeRange.end ?? .zero
                    
                    let videoTrack = VCVideoTrackDescription()
                    videoTrack.id = UUID().uuidString
                    videoTrack.sourceTimeRange = CMTimeRange(start: .zero, duration: asset.duration.seconds)
                    videoTrack.timeRange = CMTimeRange(start: start.seconds, duration: asset.duration.seconds)
                    videoTrack.mediaURL = url
                    self.trackBundle.videoTracks.append(videoTrack)
                    
                    self.vcplayer.reload(time: .zero, closure: nil)
                }
                
            case kUTTypeImage:
                if let url = info[UIImagePickerController.InfoKey.imageURL] as? URL {
                    let tracks = self.trackBundle.imageTracks + self.trackBundle.videoTracks
                    let start = tracks.max { (lhs, rhs) -> Bool in
                        return lhs.timeRange.end < rhs.timeRange.end
                    }?.timeRange.end ?? .zero
                    
                    let track = VCImageTrackDescription()
                    track.id = UUID().uuidString
                    track.timeRange = CMTimeRange(start: start.seconds, duration: 3.0)
                    track.mediaURL = url
                    self.trackBundle.imageTracks.append(track)
                    
                    self.vcplayer.reload(time: .zero, closure: nil)
                }
                
            default:
                break
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
