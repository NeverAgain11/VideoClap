//
//  VCLaminationTrackDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/6.
//

import AVFoundation

public class VCLaminationTrackDescription: NSObject, VCTrackDescriptionProtocol {
    
    public var id: String = ""
    
    public var timeRange: CMTimeRange = .zero
    
    public var mediaURL: URL?
    
    public override init() {
        super.init()
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCLaminationTrackDescription()
        copyObj.id        = self.id
        copyObj.timeRange = self.timeRange
        copyObj.mediaURL  = self.mediaURL
        return copyObj
    }
    
}
