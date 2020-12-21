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
    
    internal var imageGenerator: VCAssetImageGenerator?
    
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
    
    func assetImageGenerator() -> VCAssetImageGenerator? {
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
    
}

extension VCVideoTrackView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasourceCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VCImageCell", for: indexPath) as! VCImageCell
        cell.backgroundColor = collectionView.backgroundColor
        cell.contentView.backgroundColor = collectionView.backgroundColor
        cell.imageView.backgroundColor = collectionView.backgroundColor
        guard let videoTrack = self.videoTrack else { return cell }
        let timeValue: CMTimeValue = CMTimeValue(CGFloat(indexPath.item) * cellSize.width / widthPerTimeValue) + videoTrack.timeRange.start.value
        let time: CMTime = CMTime(value: timeValue, timescale: VCTimeControl.timeBase)
        cell.id = "\(timeValue)"
        imageGenerator?.generateCGImageAsynchronously(forTime: time, completionHandler: { (requestedTime, image, actualTime, result, closestMatch, error) in
            DispatchQueue.main.async {
                if let cgImage = image, cell.id == "\(timeValue)" {
                    let uiImage = UIImage(cgImage: cgImage)
                    cell.imageView.image = uiImage
                }
            }
        })
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
