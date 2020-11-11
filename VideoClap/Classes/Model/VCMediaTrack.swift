//
//  VCMediaTrack.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

open class VCMediaTrack: VCTrackDescription, FastEnum {
    
    public var imageURL: URL?
    
    public var isFit: Bool = true
    
    public var isFlipHorizontal: Bool = false
    
    public var filterIntensity: NSNumber = 1.0
    
    public var filterLutImageClosure: (() -> CIImage?)?
    
    /// 顺时针，弧度制，1.57顺时针旋转90度，3.14顺时针旋转180度
    public var rotateRadian: CGFloat = 0.0
    
    public var cropedRect: CGRect?
    
    public var audioEffectProvider: VCAudioEffectProviderProtocol?
    
    public func filterLutImageImage() -> CIImage? {
        return filterLutImageClosure?()
    }
    
    public func setFilterLutImageClosure(closure: @escaping () -> CIImage?) {
        filterLutImageClosure = closure
    }
    
    public override func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCMediaTrack(id: self.id, trackType: self.trackType, timeRange: self.timeRange)
        copyObj.imageURL                    = self.imageURL
        copyObj.isFit                       = self.isFit
        copyObj.isFlipHorizontal            = self.isFlipHorizontal
        copyObj.filterIntensity             = self.filterIntensity
        copyObj.filterLutImageClosure       = self.filterLutImageClosure
        copyObj.rotateRadian                = self.rotateRadian
        copyObj.cropedRect                  = self.cropedRect
        copyObj.imageClosure                = self.imageClosure
        copyObj.audioVolumeRampDescriptions = self.audioVolumeRampDescriptions
        return copyObj
    }
    
}
