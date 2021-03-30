//
//  Comparable.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/26.
//

import Foundation

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
    
    func clamped(to limits: Range<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
    
    mutating func clamping(to limits: ClosedRange<Self>) {
        self = min(max(self, limits.lowerBound), limits.upperBound)
    }
    
    mutating func clamping(to limits: Range<Self>) {
        self = min(max(self, limits.lowerBound), limits.upperBound)
    }
}
