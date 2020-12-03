//
//  VCImageTrackDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/22.
//

import AVFoundation

public class VCImageTrackDescription: NSObject, VCTrackDescriptionProtocol {
    
    public var mediaURL: URL? = nil
    
    public var id: String = ""
    
    public var prefferdTransform: CGAffineTransform? = nil
    
    public var timeRange: CMTimeRange = .zero
    
    public var isFit: Bool = true
    
    public var isFlipHorizontal: Bool = false
    
    public var filterIntensity: NSNumber = 1.0
    
    public var lutImageURL: URL?
    
    /// 顺时针，弧度制，1.57顺时针旋转90度，3.14顺时针旋转180度
    public var rotateRadian: CGFloat = 0.0
    
    /// 归一化下裁剪区域，范围（0~1）
    public var cropedRect: CGRect?
    
    public override init() {
        super.init()
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCImageTrackDescription()
        copyObj.mediaURL = mediaURL
        copyObj.id = id
        copyObj.timeRange = timeRange
        copyObj.isFit = isFit
        copyObj.isFlipHorizontal = isFlipHorizontal
        copyObj.filterIntensity = filterIntensity
        copyObj.lutImageURL = lutImageURL
        copyObj.rotateRadian = rotateRadian
        copyObj.cropedRect = cropedRect
        return copyObj
    }
    
}
