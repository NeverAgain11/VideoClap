//
//  VCTransition.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/22.
//

import AVFoundation

public class VCTransition: NSObject, NSCopying, NSMutableCopying {
    
    public var fromId: String = ""
    
    public var toId: String = ""
    
    /// 只有当轨道不重叠，但是需要过渡动画的时候，这个属性才会起作用
    public var range: VCRange = VCRange(left: 0.5, right: 0.5)
    
    internal var timeRange: CMTimeRange = CMTimeRange.zero
    
    public var transition: VCTransitionProtocol = VCAlphaTransition()
    
    public init(fromId: String = "", toId: String = "", range: VCRange = VCRange(left: 0.0, right: 0.0), transition: VCTransitionProtocol = VCAlphaTransition()) {
        self.fromId = fromId
        self.toId = toId
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
        let copyObj = VCTransition(fromId: fromId, toId: toId, range: range, transition: transition)
        copyObj.timeRange = timeRange
        return copyObj
    }
    
}
