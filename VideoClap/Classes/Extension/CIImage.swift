//
//  CIImage.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/15.
//

import Foundation

fileprivate var key = 1

public extension CIImage {
    
    var indexPath: IndexPath {
        get {
            return (objc_getAssociatedObject(self, &key) as? IndexPath) ?? IndexPath(item: 0, section: 0)
        }
        set {
            objc_setAssociatedObject(self, &key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
}
