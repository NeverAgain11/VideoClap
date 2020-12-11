//
//  VCRange.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/12.
//

import Foundation

public struct VCRange {
    /// 归一化
    public var left: Float
    /// 归一化
    public var right: Float
    public init(left: Float, right: Float) {
        self.left = left
        self.right = right
    }
}
