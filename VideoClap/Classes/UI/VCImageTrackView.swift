//
//  VCImageTrackView.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/25.
//

import UIKit

public class VCImageTrackView: MainTrackView {
    
    private lazy var ciContext: CIContext = {
        if let gpu = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: gpu)
        }
        if let eaglContext = EAGLContext(api: .openGLES3) ?? EAGLContext(api: .openGLES2) {
            return CIContext(eaglContext: eaglContext)
        }
        return CIContext()
    }()
    
    public var imageTrack: VCImageTrackDescription?
    
    private var semaphore = DispatchSemaphore(value: 1)
    
    private var loadImageQueue = DispatchQueue(label: "com.lai001.loadimage", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    
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
        guard let imageTrack = self.imageTrack else { return }
        guard cellSize.width.isZero == false else { return }
        guard let timeControl = timeControl else { return }
        let totalWidth: CGFloat = CGFloat(imageTrack.timeRange.duration.value) * timeControl.widthPerTimeVale
        datasourceCount = Int(ceil(totalWidth / cellSize.width))
        super.reloadData()
    }
    
    public func reloadData(displayRect: CGRect) {
        layout.displayRect = displayRect
        layout.invalidateLayout()
        reloadData()
    }
    
    private func thumbnail(url: URL) -> UIImage? {
        let scale = UIScreen.main.scale
        let baseSize = CGSize(width: 50, height: 50).applying(.init(scaleX: scale, y: scale))
        let size: CGSize = cellSize == .zero ? baseSize : cellSize.applying(.init(scaleX: scale, y: scale))
        let key = url.path
        if let cacheImage = ThumbnailCache.shared.imageFromMemoryCache(forKey: key) {
            return cacheImage
        } else {
            var optionalImage = CIImage(contentsOf: url)
            if var frame = optionalImage {
                let widthRatio: CGFloat = size.width / frame.extent.width
                let heightRatio: CGFloat = size.height / frame.extent.height
                let scale = widthRatio < 1.0 ? widthRatio : heightRatio
                frame = frame.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                if let cgImage = ciContext.createCGImage(frame, from: CGRect(origin: .zero, size: frame.extent.size)) {
                    optionalImage = CIImage(cgImage: cgImage)
                }
            }
            if let image = optionalImage {
                ThumbnailCache.shared.storeImage(toMemory: UIImage(ciImage: image), forKey: key)
            } else {
                ThumbnailCache.shared.storeImage(toMemory: nil, forKey: key)
            }
            return ThumbnailCache.shared.imageFromMemoryCache(forKey: key)
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
    
}

extension VCImageTrackView: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasourceCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifierGroup[0], for: indexPath) as! VCImageCell
        cell.backgroundColor = collectionView.backgroundColor
        cell.contentView.backgroundColor = collectionView.backgroundColor
        cell.imageView.backgroundColor = collectionView.backgroundColor
        guard let imageTrack = self.imageTrack else { return cell }
        guard let mediaURL = imageTrack.mediaURL else { return cell }
        cell.id = mediaURL.path
        generateThumbnailAsynchronously(url: mediaURL) { (image) in
            if cell.id == mediaURL.path {
                cell.imageView.image = image
            }
        }
        return cell
    }
    
}

