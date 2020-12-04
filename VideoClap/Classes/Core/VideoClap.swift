//
//  VideoClap.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/21.
//

import Foundation
import AVFoundation
import SwiftyBeaver
import Lottie
import SwiftyTimer

internal let log: SwiftyBeaver.Type = {
    #if DEBUG
    let console = ConsoleDestination()
    console.asynchronously = false
    console.format = "$C$L$c $n[$l] > $F: \(Thread.current) $T\n$M"
    SwiftyBeaver.addDestination(console)
    #endif
    return SwiftyBeaver.self
}()

public typealias ProgressHandler = (_ progress: Progress) -> Void

public enum VideoClapError: Error {
    case exportCancel
    case exportFailed
}

open class VideoClap: NSObject {
    
    static let ExportFolder = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("VideoClapExportVideos")
    
    public var requestCallbackHandler: VCRequestCallbackHandler = VCRequestCallbackHandler()
    
    public var videoDescription: VCVideoDescription {
        return requestCallbackHandler.videoDescription
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: UIApplication.shared)
    }
    
    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(receiveMemoryWarning(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: UIApplication.shared)
    }
    
    @objc private func receiveMemoryWarning(_ sender: Notification) {
        VideoClap.clearMemory()
    }
    
    public static func clearMemory() {
        VCImageCache.share.clearMemory()
    }
    
    public func playerItemForPlay() -> AVPlayerItem {
        let videoCompositor = VCVideoCompositor(requestCallbackHandler: requestCallbackHandler)
        requestCallbackHandler.contextChanged()
        videoCompositor.setRequestCallbackHandler(requestCallbackHandler)
        let playerItem: AVPlayerItem
        do {
             playerItem = try videoCompositor.playerItemForPlay()
        } catch let error {
            log.error(error)
            playerItem = AVPlayerItem(asset: AVAsset())
        }
        return playerItem
    }
    
    public func exportToVideo(fileName: String? = nil, progressHandler: @escaping ProgressHandler, completionHandler: @escaping ((URL?, Error?) -> Void)) {
        let playerItem = playerItemForPlay()
        let presetName = AVAssetExportPresetHighestQuality
        AVAssetExportSession.determineCompatibility(ofExportPreset: presetName, with: playerItem.asset, outputFileType: .mov) { (canExport) in
            guard canExport, let session = AVAssetExportSession(asset: playerItem.asset, presetName: presetName) else {
                completionHandler(nil, VideoClapError.exportFailed)
                return
            }
            let folder = VideoClap.ExportFolder
            
            if FileManager.default.fileExists(atPath: folder.path) == false {
                do {
                    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
                } catch let error {
                    completionHandler(nil, error)
                    return
                }
            }
            
            let exportVideoURL: URL
            
            if let fileName = fileName {
                exportVideoURL = folder.appendingPathComponent(fileName)
            } else {
                let fileName = UUID().uuidString + ".mov"
                exportVideoURL = folder.appendingPathComponent(fileName)
            }
            if FileManager.default.fileExists(atPath: exportVideoURL.path) {
                do {
                    try FileManager.default.removeItem(at: exportVideoURL)
                } catch let error {
                    completionHandler(nil, error)
                    return
                }
            }
            
            session.outputURL = exportVideoURL
            session.audioMix = playerItem.audioMix
            session.outputFileType = .mov
            session.shouldOptimizeForNetworkUse = false
            session.videoComposition = playerItem.videoComposition
            session.timeRange = CMTimeRange(start: CMTime.zero, duration: playerItem.duration)
            
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
                    timer.invalidate()
                    session.cancelExport()
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
        }
    }
    
    func imageGenerator() -> AVAssetImageGenerator {
        let playerItem = playerItemForPlay()
        let generator = AVAssetImageGenerator(asset: playerItem.asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero
        generator.maximumSize = requestCallbackHandler.videoDescription.renderSize
        generator.videoComposition = playerItem.videoComposition
        return generator
    }
    
    public func estimateVideoDuration() -> CMTime {
        let videoCompositor = VCVideoCompositor(requestCallbackHandler: requestCallbackHandler)
        return videoCompositor.estimateVideoDuration()
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
