//
//  VCTimeControl.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/18.
//

import Foundation
import AVFoundation

public class VCTimeControl: NSObject {
    
    public static let timeBase: CMTimeScale = 600
    
    let range0: Range<CGFloat> = 1..<10
    let range1: Range<CGFloat> = 10..<20
    let range2: Range<CGFloat> = 20..<24
    let range3: Range<CGFloat> = 24..<30
    let range4: Range<CGFloat> = 30..<60
    let range5: Range<CGFloat> = 60..<120
    let range6: Range<CGFloat> = 120..<200
    let range7: Range<CGFloat> = 200..<300
    let range8: ClosedRange<CGFloat> = 300...600
    
    internal var baseValue: CMTimeValue = 40
    
    public internal(set) lazy var currentTime: CMTime = CMTime(value: 0, timescale: VCTimeControl.timeBase)
    
    public internal(set) lazy var scale: CGFloat = 1
    
    public internal(set) lazy var duration: CMTime = CMTime(value: 0, timescale: VCTimeControl.timeBase)
    
    let maxScale: CGFloat = 600
    
    let minScale: CGFloat = 1
    
    public internal(set) var widthPerBaseValue: CGFloat = 0
    
    public internal(set) var widthPerTimeVale: CGFloat = 0
    
    public var isReachMax: Bool {
        return scale == maxScale
    }
    
    public var isReachMin: Bool {
        return scale == minScale
    }
    
    public func setScale(_ v: CGFloat) {
        scale = min(maxScale, max(minScale, v))
        update()
    }
    
    public func setTime(currentTime: CMTime, duration: CMTime) {
        if currentTime.isValid == false || duration.isValid == false {
            return
        }
        self.duration = max(duration, .zero)
        self.currentTime = min(max(.zero, currentTime), self.duration)
        setScale(scale)
    }
    
    public func setTime(currentTime: CMTime) {
        if currentTime.isValid == false {
            return
        }
        self.currentTime = min(max(.zero, currentTime), self.duration)
    }
    
    public func setTime(duration: CMTime) {
        if duration.isValid == false {
            return
        }
        self.duration = max(duration, .zero)
        setScale(scale)
    }
    
    internal func update() {
        switch scale {
        case range0:
            baseValue = 6000
            
        case range1:
            baseValue = 3000
            
        case range2:
            baseValue = 2400
            
        case range3:
            baseValue = 1200
            
        case range4:
            baseValue = 600
            
        case range5:
            baseValue = 300

        case range6:
            baseValue = 100
            
        case range7:
            baseValue = 60
            
        case range8:
            baseValue = 40
            
        default:
            baseValue = 40
        }
        widthPerTimeVale = scale / 300
        widthPerBaseValue = widthPerTimeVale * CGFloat(baseValue)
    }
    
}
