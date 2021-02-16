//
//  CGPoint.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/10.
//

import Foundation

extension CGPoint {
    
    func add(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: self.x + point.x, y: self.y + point.y)
    }
    
}
