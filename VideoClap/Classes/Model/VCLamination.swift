//
//  VCLamination.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/6.
//

import AVFoundation

public class VCLamination: NSObject, NSCopying, NSMutableCopying {
    
    public var id: String = ""
    
    public var timeRange: CMTimeRange = .zero
    
    public var imageClosure: (() -> CIImage?)?
    
    public init(id: String) {
        super.init()
        self.id = id
    }
    
    public func image() -> CIImage? {
        return imageClosure?()
    }
    
    public func setImageClosure(closure: (() -> CIImage?)?) {
        imageClosure = closure
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCLamination(id: self.id)
        copyObj.timeRange    = self.timeRange
        copyObj.imageClosure = self.imageClosure
        return copyObj
    }
    
}
