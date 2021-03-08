//
//  VideoCellConfig.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/18.
//

import Foundation
import SnapKit
import AVFoundation
import SDWebImage

public class VideoCellConfig: NSObject, CellConfig {
    
    public var videoTrack: VCVideoTrackDescription? {
        didSet {
            imageGenerator = assetImageGenerator()
        }
    }
    
    public var isStopLoadThumbnail: Bool = false
    
    internal var imageGenerator: VCAssetImageGenerator?
    
    private var cellSize: CGSize = .zero
    
    public init(videoTrack: VCVideoTrackDescription? = nil) {
        super.init()
        self.videoTrack = videoTrack
        self.imageGenerator = assetImageGenerator()
    }
    
    deinit {
        isStopLoadThumbnail = true
        cancelAllCGImageGeneration()
        imageGenerator = nil
        videoTrack = nil
    }
    
    private func assetImageGenerator() -> VCAssetImageGenerator? {
        imageGenerator?.cancelAllCGImageGeneration()
        imageGenerator = nil
        guard let videoTrack = self.videoTrack else { return nil }
        guard let url = videoTrack.mediaURL else { return nil }
        let asset = AVURLAsset(url: URL(fileURLWithPath: url.path))
        if asset.tracks(withMediaType: .video).isEmpty || asset.isPlayable == false {
            return nil
        }
        let generator = VCAssetImageGenerator(asset: asset)
        return generator
    }
    
    public func cancelAllCGImageGeneration() {
        imageGenerator?.cancelAllCGImageGeneration()
    }
    
    public func duration() -> CMTime? {
        return videoTrack?.timeRange.duration
    }
    
    public func targetTimeRange() -> CMTimeRange? {
        return videoTrack?.timeRange
    }
    
    public func updateCell(cell: VCImageCell, index: Int, timeControl: VCTimeControl) {
        guard let videoTrack = self.videoTrack else { return }
        guard timeControl.widthPerTimeVale.isZero == false else { return }
        let timeValue: CMTimeValue = CMTimeValue(CGFloat(index) * cellSize.width / timeControl.widthPerTimeVale) + videoTrack.sourceTimeRange.start.value
        let time: CMTime = CMTime(value: timeValue, timescale: VCTimeControl.timeBase)
        cell.id = "\(timeValue)"
        if isStopLoadThumbnail == false {
            imageGenerator?.generateCGImageAsynchronously(forTime: time, completionHandler: { (requestedTime, image, actualTime, result, error) in
                DispatchQueue.main.async {
                    if cell.id == "\(timeValue)" {
                        cell.imageView.image = image
                    }
                }
            })
        }
    }
    
    public func cellSizeUpdate(newCellSize: CGSize) {
        self.cellSize = newCellSize
        let scale: CGFloat = UIScreen.main.scale
        imageGenerator?.maximumSize = newCellSize.applying(.init(scaleX: scale, y: scale))
    }
    
    public func placeholderImage() -> UIImage? {
        return nil
    }
    
}
