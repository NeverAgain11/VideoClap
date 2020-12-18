//
//  VCTrackView.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/18.
//

import Foundation
import SnapKit
import AVFoundation
import SDWebImage

internal let thumbnailCache: SDImageCache = {
    let cache = SDImageCache()
    cache.config.maxMemoryCost = UInt(Float(ProcessInfo().physicalMemory) * 0.1)
    return cache
}()

public class VCVideoTrackView: UICollectionView {
    
    internal let flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        return layout
    }()
    
    public var videoTrack: VCVideoTrackDescription? {
        didSet {
            imageGenerator = assetImageGenerator()
        }
    }
    
    public var widthPerTimeValue: CGFloat = 0
    
    public var cellSize: CGSize = .zero
    
    internal var datasourceCount: Int = 0
    
    internal var imageGenerator: AVAssetImageGenerator?
    
    internal var lastCellSize: CGSize = .zero
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public init(frame: CGRect) {
        super.init(frame: frame, collectionViewLayout: flowLayout)
        commitInit()
    }
    
    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: flowLayout)
        commitInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commitInit() {
        isDirectionalLockEnabled = true
        showsHorizontalScrollIndicator = false
        register(VCImageCell.self, forCellWithReuseIdentifier: "VCImageCell")
        delegate = self
        dataSource = self
    }
    
    public override func reloadData() {
        guard let videoTrack = self.videoTrack else { return }
        let totalWidth: CGFloat = CGFloat(videoTrack.timeMapping.target.duration.value) * widthPerTimeValue
        datasourceCount = Int(ceil(totalWidth / cellSize.width))
        let fraction = (totalWidth / cellSize.width).truncatingRemainder(dividingBy: 1)
        lastCellSize = cellSize
        lastCellSize.width = cellSize.width * fraction
        super.reloadData()
    }
    
    func assetImageGenerator() -> AVAssetImageGenerator? {
        guard let videoTrack = self.videoTrack else { return nil }
        guard let url = videoTrack.mediaURL else { return nil }
        let asset = AVAsset(url: url)
        if asset.tracks(withMediaType: .video).isEmpty || asset.isPlayable == false {
            return nil
        }
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero
        generator.maximumSize = cellSize.applying(.init(scaleX: UIScreen.main.scale, y: UIScreen.main.scale))
        return generator
    }
    
}

extension VCVideoTrackView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasourceCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VCImageCell", for: indexPath) as! VCImageCell
        guard let videoTrack = self.videoTrack else { return cell }
        let timeValue: CMTimeValue = CMTimeValue(CGFloat(indexPath.item) * cellSize.width / widthPerTimeValue)
        let time: CMTime = CMTime(value: timeValue, timescale: VCTimeControl.timeBase)
        let key = videoTrack.id + "\(timeValue)"
        cell.id = key
        if let cacheImage = thumbnailCache.imageFromMemoryCache(forKey: key) {
            cell.imageView.image = cacheImage
        } else {
            imageGenerator?.generateCGImagesAsynchronously(forTimes: [time] as [NSValue], completionHandler: { (time, image, _, result, error) in
                if let cgImage = image {
                    let uiImage: UIImage = UIImage(cgImage: cgImage)
                    thumbnailCache.storeImage(toMemory: uiImage, forKey: key)
                    DispatchQueue.main.async {
                        if cell.id == key {
                            cell.imageView.image = UIImage(cgImage: cgImage)
                        }
                    }
                }
            })
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.item == datasourceCount - 1 && lastCellSize.width.isZero == false {
             return lastCellSize
        } else {
            return cellSize
        }
    }
    
}
