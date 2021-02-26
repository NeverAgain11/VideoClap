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
    func duration() -> CMTime
}

public class ImageCellConfig: NSObject, CellConfig {
    
    public var imageTrack: VCImageTrackDescription?
    
    private var semaphore = DispatchSemaphore(value: 1)
    
    private var loadImageQueue = DispatchQueue(label: "com.lai001.loadimage", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    
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
        if let cacheImage = ThumbnailCache.shared.uiImage(forKey: key) {
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
                }
            }
            ThumbnailCache.shared.storeImage(toMemory: optionalImage, forKey: key)
            return ThumbnailCache.shared.uiImage(forKey: key)
        }
    }
    
    private func generateThumbnailAsynchronously(url: URL, closure: @escaping (UIImage?) -> Void) {
        loadImageQueue.async {
            self.semaphore.wait()
            let image = self.thumbnail(url: url)
            DispatchQueue.main.async {
                closure(image)
                self.semaphore.signal()
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
        generateThumbnailAsynchronously(url: mediaURL) { (image) in
            if cell.id == mediaURL.path {
                cell.imageView.image = image
            }
        }
    }
    
    public func duration() -> CMTime {
        return imageTrack?.timeRange.duration ?? .zero
    }
    
}
