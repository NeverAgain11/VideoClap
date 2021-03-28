//
//  VCBaseParticle.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/18.
//

import Foundation

public class VCBaseParticle: NSObject {
    
    public var position: CGPoint = CGPoint()
    
    public var xRate: CGFloat = 0
    
    public var yRate: CGFloat = 0
    
    public var start: TimeInterval = 0
    
    public var end: TimeInterval = 0
    
    public func reset() {
        
    }
    
    public func update(progress: TimeInterval) {
        
    }
    
}
