//
//  ImageCellConfig.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/25.
//

import UIKit
import AVFoundation

public protocol CellConfig: NSObject {
    func cellSizeUpdate(newCellSize: CGSize)
    func updateCell(cell: VCImageCell, index: Int, timeControl: VCTimeControl)
    func placeholderImage() -> UIImage?
    func duration() -> CMTime?
    func targetTimeRange() -> CMTimeRange?
    func cancelAllCGImageGeneration()
}

public class ImageCellConfig: NSObject, CellConfig {
    
    public var imageTrack: VCImageTrackDescription?
    
    private static var loadImageQueue: OperationQueue = {
        var loadImageQueue = OperationQueue()
        loadImageQueue.maxConcurrentOperationCount = 1
        return loadImageQueue
    }()
    
    private var cellSize: CGSize = .zero
    
    public init(imageTrack: VCImageTrackDescription? = nil) {
        super.init()
        self.imageTrack = imageTrack
    }
    
    private func thumbnail(url: URL) -> UIImage? {
        let scale = UIScreen.main.scale
        let baseSize = CGSize(width: 50, height: 50).applying(.init(scaleX: scale, y: scale))
        let size: CGSize = cellSize == .zero ? baseSize : cellSize.applying(.init(scaleX: scale, y: scale))
        let key = url.path
        if let cacheImage = ThumbnailCache.shared.image(forKey: key) {
            return cacheImage
        } else {
            var optionalImage = CIImage(contentsOf: url)
            if var frame = optionalImage {
                let widthRatio: CGFloat = size.width / frame.extent.width
                let heightRatio: CGFloat = size.height / frame.extent.height
                let scale = widthRatio < 1.0 ? widthRatio : heightRatio
                frame = frame.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                if let cgImage = CIContext.share.createCGImage(frame, from: CGRect(origin: .zero, size: frame.extent.size)) {
                    optionalImage = CIImage(cgImage: cgImage)
                    ThumbnailCache.shared.storeImage(toMemory: UIImage(cgImage: cgImage), forKey: key)
                }
            }
            return ThumbnailCache.shared.image(forKey: key)
        }
    }
    
    private func generateThumbnailAsynchronously(url: URL, closure: @escaping (UIImage?) -> Void) {
        ImageCellConfig.loadImageQueue.addOperation { [weak self] in
            guard let self = self else { return }
            let image = self.thumbnail(url: url)
            DispatchQueue.main.async {
                closure(image)
            }
        }
    }
    
    public func cellSizeUpdate(newCellSize: CGSize) {
        self.cellSize = newCellSize
    }
    
    public func updateCell(cell: VCImageCell, index: Int, timeControl: VCTimeControl) {
        guard let imageTrack = self.imageTrack else { return }
        guard let mediaURL = imageTrack.mediaURL else { return }
        cell.id = mediaURL.path
        if let cacheImage = ThumbnailCache.shared.image(forKey: mediaURL.path) {
            cell.imageView.image = cacheImage
            return
        }
        generateThumbnailAsynchronously(url: mediaURL) { (image) in
            if cell.id == mediaURL.path {
                cell.imageView.image = image
            }
        }
    }
    
    public func duration() -> CMTime? {
        return imageTrack?.timeRange.duration
    }
    
    public func targetTimeRange() -> CMTimeRange? {
        return imageTrack?.timeRange
    }
    
    public func cancelAllCGImageGeneration() {
        
    }
    
    public func placeholderImage() -> UIImage? {
        guard let imageTrack = self.imageTrack else { return nil }
        guard let mediaURL = imageTrack.mediaURL else { return nil }
        if let cacheImage = ThumbnailCache.shared.image(forKey: mediaURL.path) {
            return cacheImage
        }
        return nil
    }
    
}
