//
//  ThumbnailCache.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/21.
//

import Foundation
import SDWebImage

class ThumbnailCache: SDImageCache {
    
    private static let _shared: SDImageCache = {
        let cache = SDImageCache()
        cache.config.maxMemoryCost = UInt(Float(ProcessInfo().physicalMemory) * 0.1)
        return cache
    }()
    
    override class var shared: SDImageCache {
        return _shared
    }
    
}
