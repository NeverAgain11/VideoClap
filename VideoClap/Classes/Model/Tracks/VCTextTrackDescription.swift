//
//  VCTextTrackDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/3.
//

import AVFoundation

public class VCTextTrackDescription: NSObject, VCTrackDescriptionProtocol {
    
    public var id: String = ""
    
    public var timeRange: CMTimeRange = .zero
    
    public var text: NSAttributedString = NSAttributedString(string: "")
    
    public var center: CGPoint = .zero
    
    /// 顺时针，弧度制，1.57顺时针旋转90度，3.14顺时针旋转180度
    public var rotateRadian: CGFloat = 0.0
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCTextTrackDescription()
        copyObj.id = id
        copyObj.timeRange = timeRange
        copyObj.rotateRadian = rotateRadian
        copyObj.text = text.mutableCopy() as! NSAttributedString
        return self
    }
    
}
