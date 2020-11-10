//
//  VCFullVideoDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import Foundation
import AVFoundation

open class VCFullVideoDescription: VCVideoDescription {
    
    public var waterMarkRect: VCRect?
    
    public var transitions: [VCTransitionProtocol] = []
    
    public var trajectories: [VCTrajectoryProtocol] = []
    
    public var laminations: [VCLamination] = []
    
    public var stickers: [VCSticker] = []
    
    public var animationStickers: [VCAnimationSticker] = []
    
    public var asyncWaterMarkImageClosure: (((CIImage?) -> Void) -> Void)?
    
    public func asyncWaterMarkImage(closure: (CIImage?) -> Void) {
        if let asyncWaterMarkImageClosure = asyncWaterMarkImageClosure {
            asyncWaterMarkImageClosure(closure)
        } else {
            closure(nil)
        }
    }
    
    public func setAsyncWaterMarkImageClosure(closure: (((CIImage?) -> Void) -> Void)?) {
        asyncWaterMarkImageClosure = closure
    }
    
    public override func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCFullVideoDescription()
        copyObj.renderSize = self.renderSize
        copyObj.renderScale = self.renderScale
        copyObj.fps = self.fps
        copyObj.mediaTracks = self.mediaTracks.map({ $0.mutableCopy() as! VCTrackDescriptionProtocol })
        copyObj.waterMarkRect = self.waterMarkRect
        copyObj.asyncWaterMarkImageClosure = self.asyncWaterMarkImageClosure
        copyObj.transitions = self.transitions
        copyObj.trajectories = self.trajectories
        copyObj.laminations = self.laminations.map({ $0.mutableCopy() as! VCLamination })
        return copyObj
    }
    
}
