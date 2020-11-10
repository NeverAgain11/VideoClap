//
//  VCVideoDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/22.
//

import AVFoundation

open class VCVideoDescription: NSObject, VCVideoDescriptionProtocol {
    
    public var renderSize: CGSize = .zero
    
    public var renderScale: Float = 1.0
    
    public var fps: Double = 24.0
    
    public var mediaTracks: [VCTrackDescriptionProtocol] = []
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCVideoDescription()
        copyObj.renderSize = self.renderSize
        copyObj.renderScale = self.renderScale
        copyObj.fps = self.fps
        copyObj.mediaTracks = self.mediaTracks.map({ $0.mutableCopy() as! VCTrackDescriptionProtocol })
        return copyObj
    }
    
}
