//
//  VCVideoDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/22.
//

import AVFoundation

open class VCVideoDescription: NSObject, NSCopying, NSMutableCopying {
    
    public var renderSize: CGSize = .zero
    
    public var renderScale: CGFloat = 1.0
    
    public var fps: Double = 24.0
    
    public var trackBundle: VCTrackBundle = VCTrackBundle()
    
    public var transitions: [VCTransition] = []
    
    /**
     # AVVideoColorPrimaries_ITU_R_709_2
     # AVVideoColorPrimaries_SMPTE_C
     # AVVideoColorPrimaries_P3_D65
     # AVVideoColorPrimaries_ITU_R_2020
     */
    @available(iOS 10.0, *)
    public lazy var colorPrimaries: String? = nil
    
    /**
     # AVVideoTransferFunction_ITU_R_709_2
     # AVVideoTransferFunction_SMPTE_ST_2084_PQ
     # AVVideoTransferFunction_ITU_R_2100_HLG
     */
    @available(iOS 10.0, *)
    public lazy var colorTransferFunction: String? = nil
    
    /**
     # AVVideoYCbCrMatrix_ITU_R_709_2
     # AVVideoYCbCrMatrix_ITU_R_601_4
     # AVVideoYCbCrMatrix_ITU_R_2020
     */
    @available(iOS 10.0, *)
    public lazy var colorYCbCrMatrix: String? = nil
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCVideoDescription()
        copyObj.renderSize  = renderSize
        copyObj.renderScale = renderScale
        copyObj.fps         = fps
        copyObj.trackBundle = trackBundle.mutableCopy() as! VCTrackBundle
        copyObj.transitions = transitions
        if #available(iOS 10.0, *) {
            copyObj.colorPrimaries        = colorPrimaries
            copyObj.colorTransferFunction = colorTransferFunction
            copyObj.colorYCbCrMatrix      = colorYCbCrMatrix
        }
        return copyObj
    }
    
}
