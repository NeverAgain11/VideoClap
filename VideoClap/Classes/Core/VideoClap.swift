//
//  VideoClap.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/21.
//

import Foundation
import AVFoundation
import Lottie
import SwiftyTimer

public typealias ProgressHandler = (_ progress: Progress) -> Void
public typealias CancelClosure = () -> Void

public enum VideoClapError: Error {
    case exportCancel
    case exportFailed
}

open class VideoClap: NSObject, VCMediaServicesObserver {
    
    static let ExportFolder = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("VideoClapExportVideos")
    
    public var requestCallbackHandler: VCRequestCallbackHandler = VCRequestCallbackHandler()
    
    public var videoDescription: VCVideoDescription {
        get {
            return requestCallbackHandler.videoDescription
        }
        set {
            requestCallbackHandler.videoDescription = newValue
        }
    }
    
    private lazy var videoCompositor: VCVideoCompositor = {
        let videoCompositor = VCVideoCompositor(requestCallbackHandler: requestCallbackHandler)
        return videoCompositor
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: UIApplication.shared)
    }
    
    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(receiveMemoryWarning(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: UIApplication.shared)
        
        NotificationCenter.default.addObserver(self, selector: #selector(mediaServicesWereResetNotification(_:)), name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(mediaServicesWereLostNotification(_:)), name: AVAudioSession.mediaServicesWereLostNotification, object: nil)
    }
    
    @objc public func mediaServicesWereResetNotification(_ sender: Notification) {
        videoCompositor.mediaServicesWereResetNotification(sender)
    }
    
    @objc public func mediaServicesWereLostNotification(_ sender: Notification) {
        videoCompositor.mediaServicesWereLostNotification(sender)
    }
    
    @objc private func receiveMemoryWarning(_ sender: Notification) {
        VideoClap.clearMemory()
    }
    
    public static func clearMemory() {
        VCImageCache.share.clearMemory()
    }
    
    public func playerItemForPlay() throws -> AVPlayerItem {
        let trackBundle = videoDescription.trackBundle
        trackBundle.audioTracks.forEach({ $0.prepare(description: videoDescription) })
        trackBundle.videoTracks.forEach({ $0.prepare(description: videoDescription) })
        trackBundle.imageTracks.forEach({ $0.prepare(description: videoDescription) })
        let playerItem = try videoCompositor.playerItemForPlay()
        return playerItem
    }
    
    @discardableResult
    public func export(fileName: String? = nil, progressHandler: @escaping ProgressHandler, completionHandler: @escaping ((URL?, Error?) -> Void)) -> CancelClosure? {
        do {
            let item = try playerItemForPlay()
            return export(playerItem: item, fileName: fileName, progressHandler: progressHandler, completionHandler: completionHandler)
        } catch let error {
            completionHandler(nil, error)
            return nil 
        }
    }
    
    @discardableResult
    public func export(playerItem: AVPlayerItem, fileName: String? = nil, progressHandler: @escaping ProgressHandler, completionHandler: @escaping ((URL?, Error?) -> Void)) -> CancelClosure? {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.audioProcessing, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch let error {
            log.error(error)
        }
        
        if playerItem.asset.tracks(withMediaType: .audio).isEmpty && playerItem.asset.tracks(withMediaType: .video).isEmpty {
            completionHandler(nil, VideoClapError.exportFailed)
            return nil
        }
        
        guard let session = AVAssetExportSession(asset: playerItem.asset, presetName: AVAssetExportPresetHighestQuality) else {
            completionHandler(nil, VideoClapError.exportFailed)
            return nil
        }
        let folder = VideoClap.ExportFolder
        
        if FileManager.default.fileExists(atPath: folder.path) == false {
            do {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                completionHandler(nil, error)
                return nil
            }
        }
        
        let exportVideoURL: URL
        let fileNameExt: String = "mov"
        if var fileName = fileName {
            if fileName.pathExtension != fileNameExt {
                fileName = fileName.deletingPathExtension().appendingPathExtension(fileNameExt) ?? fileName
            }
            exportVideoURL = folder.appendingPathComponent(fileName)
        } else {
            let fileName = UUID().uuidString.appendingPathExtension(fileNameExt) ?? UUID().uuidString
            exportVideoURL = folder.appendingPathComponent(fileName)
        }
        if FileManager.default.fileExists(atPath: exportVideoURL.path) {
            do {
                try FileManager.default.removeItem(at: exportVideoURL)
            } catch let error {
                completionHandler(nil, error)
                return nil
            }
        }
        
        session.outputURL = exportVideoURL
        session.audioMix = playerItem.audioMix
        session.outputFileType = .mov
        session.shouldOptimizeForNetworkUse = true
        session.videoComposition = playerItem.videoComposition
        session.directoryForTemporaryFiles = VideoClap.ExportFolder
        session.canPerformMultiplePassesOverSourceMediaData = false
        session.audioTimePitchAlgorithm = .spectral
        
        let den: Int64 = 100
        let progress = Progress(totalUnitCount: den)
        
        session.exportAsynchronously {
            DispatchQueue.main.async {
                if progress.isCancelled {
                    completionHandler(nil, VideoClapError.exportCancel)
                } else {
                    if session.status == .completed {
                        completionHandler(exportVideoURL, nil)
                    } else {
                        completionHandler(nil, session.error)
                    }
                    progress.cancel()
                }
            }
        }
        
        let timer = Timer.every(0.1) { (timer: Timer) in
            if progress.isCancelled {
                if timer.isValid {
                    timer.invalidate()
                }
                if session.status != .cancelled {
                    session.cancelExport()
                }
            } else {
                progress.completedUnitCount = Int64(min(1.0, session.progress) * Float(den))
                progressHandler(progress)
            }
        }
        if Thread.current.isMainThread {
            
        } else {
            timer.start(modes: .default)
            RunLoop.current.run()
        }

        return {
            progress.cancel()
            timer.invalidate()
            session.cancelExport()
        }
    }
    
    func imageGenerator() -> AVAssetImageGenerator {
        do {
            let playerItem = try playerItemForPlay()
            let generator = AVAssetImageGenerator(asset: playerItem.asset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceAfter = .zero
            generator.requestedTimeToleranceBefore = .zero
            generator.maximumSize = requestCallbackHandler.videoDescription.renderSize
            generator.videoComposition = playerItem.videoComposition
            return generator
        } catch let error {
            return AVAssetImageGenerator(asset: AVAsset())
        }
    }
    
    public func estimateVideoDuration() -> CMTime {
        return (try? playerItemForPlay().asset.duration) ?? .zero
    }
    
    public static func cleanExportFolder() {
        let folder = VideoClap.ExportFolder
        if FileManager.default.fileExists(atPath: folder.path) {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: folder.path)
                for content in contents {
                    try FileManager.default.removeItem(atPath: folder.appendingPathComponent(content).path)
                }
            } catch let error {
                log.error(error)
            }
        }
    }
    
}
