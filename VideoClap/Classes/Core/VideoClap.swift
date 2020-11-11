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
    
    public var requestCallbackHandler: VCRequestCallbackHandlerProtocol = VCRequestCallbackHandler()
    
    public var videoDescription: VCVideoDescriptionProtocol {
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

    }
    
    public func playerItemForPlay() -> AVPlayerItem {
        let videoCompositor = VCVideoCompositor()
        videoCompositor.setRequestCallbackHandler(requestCallbackHandler)
        let playerItem = videoCompositor.playerItemForPlay()
//        playerItem.seekingWaitsForVideoCompositionRendering = false
        return playerItem
    }
    
    public func exportToVideo(fileName: String? = nil, progressHandler: @escaping ProgressHandler, completionHandler: @escaping ((URL?, Error?) -> Void)) {
        let playerItem = playerItemForPlay()
//        playerItem.seekingWaitsForVideoCompositionRendering = true
        let presetName = AVAssetExportPresetHighestQuality
        AVAssetExportSession.determineCompatibility(ofExportPreset: presetName, with: playerItem.asset, outputFileType: .mov) { (canExport) in
            guard canExport, let session = AVAssetExportSession(asset: playerItem.asset, presetName: presetName) else {
                completionHandler(nil, VideoClapError.exportFailed)
                return
            }
            
            let exportVideoURL: URL
            
            if let fileName = fileName {
                exportVideoURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            } else {
                let df = DateFormatter()
                df.dateFormat = "YYYY_MM_dd_KK_mm_ss"
                let fileName = df.string(from: Date()) + ".mov"
                exportVideoURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
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
            RunLoop.current.run()
            timer.fire()
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
        let duration = videoDescription.mediaTracks.map({ $0.timeRange.end }).max() ?? .zero
        return duration
    }
    
}
