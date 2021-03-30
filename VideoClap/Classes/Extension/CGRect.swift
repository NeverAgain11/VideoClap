//
//  CGRect.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/11.
//

import Foundation

extension CGRect {
    
    var center: CGPoint {
        get {
            return CGPoint(x: midX, y: midY)
        }
        
        set {
            self.origin = CGPoint(x: newValue.x - width / 2.0, y: newValue.y - height / 2.0)
        }
    }
    
    func add(_ rect: CGRect) -> CGRect {
        return CGRect(x: self.origin.x + rect.origin.x,
                      y: self.origin.y + rect.origin.y,
                      width: self.size.width + rect.size.width,
                      height: self.size.height + rect.size.height)
    }
    
}
