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
    
    internal func draw(at point: CGPoint) {
        UIImage(ciImage: self).draw(at: point)
    }
    
    internal func draw(at point: CGPoint, blendMode: CGBlendMode, alpha: CGFloat) {
        UIImage(ciImage: self).draw(at: point, blendMode: blendMode, alpha: alpha)
    }
    
    internal func draw(in rect: CGRect) {
        UIImage(ciImage: self).draw(in: rect)
    }
    
    internal func draw(in rect: CGRect, blendMode: CGBlendMode, alpha: CGFloat) {
        UIImage(ciImage: self).draw(in: rect, blendMode: blendMode, alpha: alpha)
    }
    
    internal func drawAsPattern(in rect: CGRect) {
        UIImage(ciImage: self).drawAsPattern(in: rect)
    }
    
    internal func withTintColor(_ color: UIColor) -> CIImage {
        let renderer = VCGraphicsRenderer(self.extent.size)
        return renderer.ciImage { (_) in
            color.setFill()
            UIRectFill(extent)
            self.draw(at: .zero, blendMode: .destinationIn, alpha: 1.0)
        } ?? self
    }
    
}
