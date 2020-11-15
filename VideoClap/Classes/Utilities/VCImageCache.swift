//
//  VCImageCache.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/15.
//

import Foundation
import SDWebImage

internal class VCImageCache: NSObject {
    
    static let share = VCImageCache()
    
    private lazy var cache: SDImageCache = {
        let cache = SDImageCache()
        cache.config.maxMemoryCost = UInt(Float(ProcessInfo().physicalMemory) * 0.3)
        return cache
    }()
    
    func image(forKey key: String?) -> CIImage? {
        
        return cache.imageFromMemoryCache(forKey: key)?.ciImage
    }
    
    func storeImage(toMemory image: CIImage?, forKey key: String?) {
        if let image = image {
            cache.storeImage(toMemory: UIImage(ciImage: image), forKey: key)
        }
    }
    
    func clearMemory() {
        cache.clearMemory()
    }
    
}
