//
//  CGSize.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/14.
//

import Foundation

internal extension CGSize {
    
    func scaling<T: BinaryFloatingPoint>(_ v: T) -> CGSize {
        return self.applying(.init(scaleX: CGFloat(v), y: CGFloat(v)))
    }
    
    mutating func scale<T: BinaryFloatingPoint>(_ v: T) {
        self = self.applying(.init(scaleX: CGFloat(v), y: CGFloat(v)))
    }
    
}
