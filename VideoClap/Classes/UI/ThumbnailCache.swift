//
//  ThumbnailCache.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/21.
//

import Foundation
import SDWebImage

class ThumbnailCache: NSObject {
    
    private static let _shared: VCImageCache = {
        let cache = VCImageCache(maxMemoryCost: .low)
        return cache
    }()
    
    class var shared: VCImageCache {
        return _shared
    }
    
}
