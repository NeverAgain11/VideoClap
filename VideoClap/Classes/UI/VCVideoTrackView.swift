//
//  VCVideoTrackView.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/18.
//

import Foundation
import SnapKit
import AVFoundation
import SDWebImage

public class VCVideoTrackView: MainTrackView {
    
    public var videoTrack: VCVideoTrackDescription? {
        didSet {
            imageGenerator = assetImageGenerator()
        }
    }
    
    public var isStopLoadThumbnail: Bool = false
    
    internal var imageGenerator: VCAssetImageGenerator?
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commitInit()
    }
    
    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        commitInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commitInit() {
        dataSource = self
    }
    
    public override func reloadData() {
        guard let videoTrack = self.videoTrack else { return }
        guard cellSize.width.isZero == false else { return }
        guard let timeControl = timeControl else { return }
        let totalWidth: CGFloat = CGFloat(videoTrack.timeMapping.target.duration.value) * timeControl.widthPerTimeVale
        datasourceCount = Int(ceil(totalWidth / cellSize.width))
        super.reloadData()
    }
    
    public func reloadData(displayRect: CGRect) {
        layout.displayRect = displayRect
        layout.invalidateLayout()
        reloadData()
    }
    
    private func assetImageGenerator() -> VCAssetImageGenerator? {
        imageGenerator?.cancelAllCGImageGeneration()
        imageGenerator = nil
        guard let videoTrack = self.videoTrack else { return nil }
        guard let url = videoTrack.mediaURL else { return nil }
        let asset = AVURLAsset(url: url)
        if asset.tracks(withMediaType: .video).isEmpty || asset.isPlayable == false {
            return nil
        }
        let generator = VCAssetImageGenerator(asset: asset)
        let scale: CGFloat = UIScreen.main.scale
        generator.maximumSize = cellSize.applying(.init(scaleX: scale, y: scale))
        return generator
    }
    
    public func cancelAllCGImageGeneration() {
        imageGenerator?.cancelAllCGImageGeneration()
    }
    
}

extension VCVideoTrackView: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasourceCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.item % reuseIdentifierGroup.count
        let reuseIdentifier = reuseIdentifierGroup[index]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! VCImageCell
        cell.backgroundColor = collectionView.backgroundColor
        cell.contentView.backgroundColor = collectionView.backgroundColor
        cell.imageView.backgroundColor = collectionView.backgroundColor
        guard let videoTrack = self.videoTrack else { return cell }
        guard let timeControl = timeControl else { return cell }
        guard timeControl.widthPerTimeVale.isZero == false else { return cell }
        let timeValue: CMTimeValue = CMTimeValue(CGFloat(indexPath.item) * cellSize.width / timeControl.widthPerTimeVale) + videoTrack.timeRange.start.value
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
        return cell
    }
    
}

