//
//  VCVideoDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/22.
//

import AVFoundation

open class VCVideoDescription: NSObject, NSCopying, NSMutableCopying {
    
    public var renderSize: CGSize = .zero
    
    public var renderScale: Float = 1.0
    
    public var fps: Double = 24.0
    
    public var waterMarkRect: VCRect?
    
    public var waterMarkImageURL: URL?
    
    public var trackBundle: VCTrackBundle = .init()
    
    public var transitions: [VCTransitionProtocol] = []
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCVideoDescription()
        copyObj.renderSize  = self.renderSize
        copyObj.renderScale = self.renderScale
        copyObj.fps         = self.fps
        copyObj.trackBundle = self.trackBundle.mutableCopy() as! VCTrackBundle
        copyObj.transitions = self.transitions
        return copyObj
    }
    
}
