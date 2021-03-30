//
//  VCRect.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

public struct VCRect: Equatable {
    
    public var center: CGPoint
    public var size: CGSize
    
    public var x: CGFloat {
        get {
            return center.x
        }
        set {
            center.x = newValue
        }
    }
    
    public var y: CGFloat {
        get {
            return center.y
        }
        set {
            center.y = newValue
        }
    }
    
    public var width: CGFloat {
        get {
            return size.width
        }
        set {
            size.width = newValue
        }
    }
    
    public var height: CGFloat {
        get {
            return size.height
        }
        set {
            size.height = newValue
        }
    }
    
    public static var zero: VCRect {
        return VCRect(center: .zero, size: .zero)
    }
    
    public init(x centerX: CGFloat, y centerY: CGFloat, width: CGFloat, height: CGFloat) {
        self.center = CGPoint(x: centerX, y: centerY)
        self.size = CGSize(width: width, height: height)
    }
    
    public init(x centerX: CGFloat, y centerY: CGFloat, size: CGSize) {
        self.center = CGPoint(x: centerX, y: centerY)
        self.size = size
    }
    
    public init(center: CGPoint, size: CGSize) {
        self.center = center
        self.size = size
    }
    
    public init(center: CGPoint, width: CGFloat, height: CGFloat) {
        self.center = center
        self.size = CGSize(width: width, height: height)
    }
}
