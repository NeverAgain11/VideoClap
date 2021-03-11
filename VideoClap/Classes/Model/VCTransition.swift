//
//  VCTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/22.
//

import AVFoundation

public class VCTransition: NSObject, NSCopying, NSMutableCopying {
    
    public var fromTrack: VCImageTrackDescription?
    
    public var toTrack: VCImageTrackDescription?
    
    public var range: VCRange = VCRange(left: 0.5, right: 0.5)
    
    internal var timeRange: CMTimeRange = CMTimeRange.zero
    
    public var transition: VCTransitionProtocol = VCAlphaTransition()
    
    public init(fromTrack: VCImageTrackDescription? = nil, toTrack: VCImageTrackDescription? = nil, range: VCRange = VCRange(left: 0.0, right: 0.0), transition: VCTransitionProtocol = VCAlphaTransition()) {
        self.fromTrack = fromTrack
        self.toTrack = toTrack
        self.range = range
        self.transition = transition
    }
    
    internal func transition(renderSize: CGSize, progress: Float, fromImage: CIImage, toImage: CIImage) -> CIImage? {
        return transition.transition(renderSize: renderSize, progress: progress, fromImage: fromImage, toImage: toImage)
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCTransition(fromTrack: fromTrack, toTrack: toTrack, range: range, transition: transition)
        copyObj.timeRange = timeRange
        return copyObj
    }
    
}
