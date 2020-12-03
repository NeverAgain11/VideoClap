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
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCTextTrackDescription()
        copyObj.id = id
        copyObj.timeRange = timeRange
        copyObj.text = text.mutableCopy() as! NSAttributedString
        return self
    }
    
}
