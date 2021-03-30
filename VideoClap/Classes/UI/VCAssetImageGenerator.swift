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
                                                           _ image: UIImage?,
                                                           _ actualTime: CMTime,
                                                           _ result: AVAssetImageGenerator.Result,
                                                           _ error: Error?) -> Void

public class VCAssetImageGenerator: AVAssetImageGenerator {
    
    internal let url: URL
    
    private var frameLoading: [CMTimeValue:Bool] = [:]
    
    public init(asset: AVURLAsset) {
        self.url = asset.url
        super.init(asset: asset)
        appliesPreferredTrackTransform = true
        requestedTimeToleranceAfter = .zero
        requestedTimeToleranceBefore = .zero
    }
    
    public func generateCGImageAsynchronously(forTime requestedTime: CMTime, completionHandler handler: @escaping VCAssetImageGeneratorCompletionHandler) {
        let time: CMTime = CMTimeConvertScale(requestedTime, timescale: 600, method: .default)
        let timeValue: CMTimeValue = time.value
        
        let cacheKey = url.path + "\(timeValue)"
        
        if frameLoading[timeValue] == true {
            return
        }
        
        if let cacheImage = ThumbnailCache.shared.image(forKey: cacheKey) {
            handler(time,
                    cacheImage,
                    time,
                    AVAssetImageGenerator.Result.succeeded,
                    nil)
        } else {
            frameLoading[timeValue] = true
            generateCGImagesAsynchronously(forTimes: [time] as [NSValue], completionHandler: { [weak self] (requestedTime, image, actualTime, result, error) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.frameLoading.removeValue(forKey: timeValue)
                }
                var uiImage: UIImage?
                if let cgImage = image {
                    uiImage = UIImage(cgImage: cgImage)   
                }
                ThumbnailCache.shared.storeImage(toMemory: uiImage, forKey: cacheKey)
                handler(requestedTime,
                        uiImage,
                        actualTime,
                        result,
                        error)
            })
        }
    }
    
}
