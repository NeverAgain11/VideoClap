//
//  VCRect.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

public struct VCRect {
    public var normalizeCenter: CGPoint
    public var normalizeWidth: CGFloat
    public var normalizeHeight: CGFloat
    
    public init(normalizeCenter: CGPoint, normalizeSize: CGSize) {
        self.normalizeCenter = normalizeCenter
        self.normalizeWidth = normalizeSize.width
        self.normalizeHeight = normalizeSize.height
    }
    
    public init(normalizeCenter: CGPoint, normalizeWidth: CGFloat, normalizeHeight: CGFloat) {
        self.normalizeCenter = normalizeCenter
        self.normalizeWidth = normalizeWidth
        self.normalizeHeight = normalizeHeight
    }
}
