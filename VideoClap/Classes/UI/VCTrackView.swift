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

public class VCVideoTrackViewLayout: UICollectionViewLayout {
    
    public var displayRect: CGRect?
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = self.collectionView as? VCVideoTrackView else { return nil }
        guard let displayRect = displayRect else { return nil }
        var attrs: [UICollectionViewLayoutAttributes] = []
        
        let cellSize: CGSize = collectionView.cellSize
        let cellWidth: CGFloat = cellSize.width
        let datasourceCount: Int = collectionView.datasourceCount
        
        let upper = max(0, Int(floor(displayRect.minX / cellWidth)) )
        let low = min(datasourceCount, Int(ceil(displayRect.maxX / cellWidth)) )
        
        if low <= upper {
            return nil
        }
        
        let y: CGFloat = 0
        for index in upper..<low {
            let x: CGFloat = CGFloat(index) * cellWidth
            let attr = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: 0))
            attr.frame = CGRect(origin: CGPoint(x: x, y: y), size: cellSize)
            attrs.append(attr)
        }
        
        return attrs
    }
    
    public override var collectionViewContentSize: CGSize {
        guard let collectionView = self.collectionView as? VCVideoTrackView else { return .zero }
        return collectionView.bounds.size
    }
    
}

public class VCVideoTrackViewFlowLayout: UICollectionViewFlowLayout {
    
    public override init() {
        super.init()
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        scrollDirection = .horizontal
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

public class VCVideoTrackView: UICollectionView {
    
    internal let layout: VCVideoTrackViewLayout = {
        let layout = VCVideoTrackViewLayout()
        return layout
    }()
    
    public var videoTrack: VCVideoTrackDescription? {
        didSet {
            imageGenerator = assetImageGenerator()
        }
    }
    
    public var timeControl: VCTimeControl?
    
    public var cellSize: CGSize = .zero
    
    internal var datasourceCount: Int = 0
    
    internal var imageGenerator: VCAssetImageGenerator?
    
    internal var lastCellSize: CGSize = .zero
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public init(frame: CGRect) {
        super.init(frame: frame, collectionViewLayout: layout)
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
        isDirectionalLockEnabled = true
        showsHorizontalScrollIndicator = false
        register(VCImageCell.self, forCellWithReuseIdentifier: "VCImageCell")
        delegate = self
        dataSource = self
    }
    
    public override func reloadData() {
        guard let videoTrack = self.videoTrack else { return }
        guard cellSize.width.isZero == false else { return }
        guard let timeControl = timeControl else { return }
        let totalWidth: CGFloat = CGFloat(videoTrack.timeMapping.target.duration.value) * timeControl.widthPerTimeVale
        datasourceCount = Int(ceil(totalWidth / cellSize.width))
        let fraction = (totalWidth / cellSize.width).truncatingRemainder(dividingBy: 1)
        lastCellSize = cellSize
        lastCellSize.width = cellSize.width * fraction
        super.reloadData()
    }
    
    public func reloadData(displayRect: CGRect) {
        layout.displayRect = displayRect
        layout.invalidateLayout()
        reloadData()
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
    
    public func cancelAllCGImageGeneration() {
        imageGenerator?.cancelAllCGImageGeneration()
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
        guard let timeControl = timeControl else { return cell }
        guard timeControl.widthPerTimeVale.isZero == false else { return cell }
        let timeValue: CMTimeValue = CMTimeValue(CGFloat(indexPath.item) * cellSize.width / timeControl.widthPerTimeVale) + videoTrack.timeRange.start.value
        let time: CMTime = CMTime(value: timeValue, timescale: VCTimeControl.timeBase)
//        let timeValue: CMTimeValue = CMTimeValue(indexPath.item) * timeControl.intervalTime.value + videoTrack.timeRange.start.value
//        let time: CMTime = CMTime(value: timeValue, timescale: VCTimeControl.timeBase)
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
