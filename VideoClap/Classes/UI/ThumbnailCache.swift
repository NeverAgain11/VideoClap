//
//  ThumbnailCache.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/21.
//

import Foundation
import SDWebImage

public class ThumbnailCache: NSObject {
    
    public static let shared = ThumbnailCache()
    
    private lazy var cache: SDImageCache = {
        let cache = SDImageCache(namespace: "ThumbnailCache", diskCacheDirectory: nil, config: SDImageCacheConfig())
        cache.config.maxMemoryCost = 50
        return cache
    }()
    
    public func image(forKey key: String?) -> UIImage? {
        return cache.imageFromCache(forKey: key)
    }
    
    public func storeImage(toMemory image: UIImage?, forKey key: String?) {
        cache.storeImage(toMemory: image, forKey: key)
    }
    
    public func clearCache() {
        cache.clear(with: .all, completion: nil)
    }
    
}
