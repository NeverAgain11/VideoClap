//
//  VCImageCache.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/15.
//

import Foundation
import SDWebImage

internal enum MemoryCostLevel {
    case low
    case middle
    case high
    case custom(Float)
    case customBytes(UInt)
    
    func uint() -> UInt {
        switch self {
        case .low:
            return UInt(Float(ProcessInfo().physicalMemory) * 0.1)
        case .middle:
            return UInt(Float(ProcessInfo().physicalMemory) * 0.3)
        case .high:
            return UInt(Float(ProcessInfo().physicalMemory) * 0.5)
        case .custom(let p):
            if p <= 0 {
                return 0
            }
            return UInt(Float(ProcessInfo().physicalMemory) * p)
        case .customBytes(let b):
            return b
        }
    }
}

internal class VCImageCache: NSObject {
    
    static let share = VCImageCache()
    
    var maxMemoryCost = MemoryCostLevel.middle {
        didSet {
            cache.config.maxMemoryCost = maxMemoryCost.uint()
        }
    }
    
    private lazy var cache: SDImageCache = {
        let cache = SDImageCache()
        cache.config.maxMemoryCost = maxMemoryCost.uint()
        return cache
    }()
    
    init(maxMemoryCost: MemoryCostLevel = .middle) {
        super.init()
        self.maxMemoryCost = maxMemoryCost
    }
    
    func ciImage(forKey key: String?) -> CIImage? {
        return cache.imageFromMemoryCache(forKey: key)?.ciImage
    }
    
    func uiImage(forKey key: String?) -> UIImage? {
        return cache.imageFromMemoryCache(forKey: key)
    }
    
    func storeImage(toMemory image: CIImage?, forKey key: String?) {
        if let image = image {
            cache.storeImage(toMemory: UIImage(ciImage: image), forKey: key)
        }
    }
    
    func storeImage(toMemory image: UIImage?, forKey key: String?) {
        if let image = image {
            cache.storeImage(toMemory: image, forKey: key)
        }
    }
    
    func clearMemory() {
        cache.clearMemory()
    }
    
}
