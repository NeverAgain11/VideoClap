//
//  VCAssetImageGenerator.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/21.
//

import Foundation
import AVFoundation
import SDWebImage

public typealias VCAssetImageGeneratorCompletionHandler = (_ requestedTime: CMTime,
                                                           _ image: CGImage?,
                                                           _ actualTime: CMTime,
                                                           _ result: AVAssetImageGenerator.Result,
                                                           _ closestMatch: Bool,
                                                           _ error: Error?) -> Void

public class VCAssetImageGenerator: AVAssetImageGenerator {
    
    internal let url: URL
    
    private var frameLoading: [CMTimeValue:Bool] = [:]
    
    private var storeTimeValues: Set<CMTimeValue> = .init()
    
    public init(asset: AVURLAsset) {
        self.url = asset.url
        super.init(asset: asset)
        appliesPreferredTrackTransform = true
        requestedTimeToleranceAfter = .zero
        requestedTimeToleranceBefore = .zero
    }
    
    private func closestMatch(inputValue: CMTimeValue) -> CMTimeValue? {
        return storeTimeValues.reduce(storeTimeValues.first) { (result, value: CMTimeValue) -> CMTimeValue? in
            if result == nil {
                return nil
            }
            return abs(result.unsafelyUnwrapped - inputValue) < abs(value - inputValue) ? result : value
        }
    }
    
    public func generateCGImageAsynchronously(forTime requestedTime: CMTime, completionHandler handler: @escaping VCAssetImageGeneratorCompletionHandler) {
        let time: CMTime = CMTimeConvertScale(requestedTime, timescale: 600, method: .default)
        let timeValue: CMTimeValue = time.value
        
        let cacheKey = url.path + "\(timeValue)"
        
        if frameLoading[timeValue] == true {
            return
        }
        
        if let cacheImage = ThumbnailCache.shared.imageFromMemoryCache(forKey: cacheKey) {
            handler(time,
                    cacheImage.cgImage,
                    time,
                    AVAssetImageGenerator.Result.succeeded,
                    false,
                    nil)
        } else {
            if let closestMatchValue = closestMatch(inputValue: timeValue) {
                if let cacheImage = ThumbnailCache.shared.imageFromMemoryCache(forKey: url.path + "\(closestMatchValue)") {
                    handler(time,
                            cacheImage.cgImage,
                            time,
                            AVAssetImageGenerator.Result.succeeded,
                            true,
                            nil)
                }
            }
            frameLoading[timeValue] = true
            generateCGImagesAsynchronously(forTimes: [time] as [NSValue], completionHandler: { [weak self] (requestedTime, image, actualTime, result, error) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if result == .succeeded && error == nil && image != nil {
                        self.storeTimeValues.insert(timeValue)
                    }
                    self.frameLoading.removeValue(forKey: timeValue)
                }
                if let cgImage = image {
                    let uiImage: UIImage = UIImage(cgImage: cgImage)
                    ThumbnailCache.shared.storeImage(toMemory: uiImage, forKey: cacheKey)
                } else {
                    ThumbnailCache.shared.storeImage(toMemory: nil, forKey: cacheKey)
                }
                handler(requestedTime,
                        image,
                        actualTime,
                        result,
                        false,
                        error)
            })
        }
    }
    
}
