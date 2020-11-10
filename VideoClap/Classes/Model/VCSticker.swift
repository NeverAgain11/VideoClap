//
//  VCSticker.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/9.
//

import AVFoundation

public class VCSticker: NSObject {
    
    public var id: String = ""
    
    public var rect: VCRect = VCRect(normalizeCenter: CGPoint(x: 0.5, y: 0.5), normalizeSize: CGSize(width: 0.5, height: 0.5))
    
    public var rotateDegree: Float = .zero
    
    public var timeRange: CMTimeRange = .zero
    
    public var asyncImageClosure: (((CIImage?) -> Void) -> Void)?
    
    public func asyncImage(closure: (CIImage?) -> Void) {
        asyncImageClosure?(closure)
    }
    
    public func setAsyncImageClosure(closure: (((CIImage?) -> Void) -> Void)?) {
        asyncImageClosure = closure
    }
    
}
