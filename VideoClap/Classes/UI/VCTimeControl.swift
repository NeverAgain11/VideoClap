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
    
    public internal(set) var intervalTime: CMTime = CMTime(seconds: 20.0, preferredTimescale: VCTimeControl.timeBase)
    
    public internal(set) lazy var currentTime: CMTime = CMTime(value: 0, timescale: VCTimeControl.timeBase)
    
    public internal(set) lazy var scale: CGFloat = (maxScale + minScale) / 2.0
    
    public internal(set) lazy var duration: CMTime = CMTime(value: 0, timescale: VCTimeControl.timeBase)
    
    public private(set) lazy var maxScale: CGFloat = 12000
    
    public let minScale: CGFloat = 30
    
    public internal(set) var widthPerBaseValue: CGFloat = 0
    
    public internal(set) var widthPerTimeVale: CGFloat = 0
    
    public var isReachMax: Bool {
        return scale == maxScale
    }
    
    public var isReachMin: Bool {
        return scale == minScale
    }
    
    public var maxLength: CGFloat {
        return widthPerTimeVale * CGFloat(duration.value)
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
    
    private func update() {
        switch scale {
        case 30..<60:
            intervalTime = CMTime(seconds: 20.0, preferredTimescale: VCTimeControl.timeBase)
        
        case 60..<120:
            intervalTime = CMTime(seconds: 10.0, preferredTimescale: VCTimeControl.timeBase)
            
        case 120..<200:
            intervalTime = CMTime(seconds: 5.0, preferredTimescale: VCTimeControl.timeBase)
            
        case 200..<300:
            intervalTime = CMTime(seconds: 3.0, preferredTimescale: VCTimeControl.timeBase)
            
        case 300..<600:
            intervalTime = CMTime(seconds: 2.0, preferredTimescale: VCTimeControl.timeBase)
            
        case 600..<1200:
            intervalTime = CMTime(seconds: 1.0, preferredTimescale: VCTimeControl.timeBase)
            
        case 1200..<1800:
            intervalTime = CMTime(seconds: 1.0 / 2.0, preferredTimescale: VCTimeControl.timeBase)

        case 1800..<3600:
            intervalTime = CMTime(seconds: 1.0 / 3.0, preferredTimescale: VCTimeControl.timeBase)
            
        case 3600..<6000:
            intervalTime = CMTime(seconds: 1.0 / 6.0, preferredTimescale: VCTimeControl.timeBase)
            
        case 6000..<9000:
            intervalTime = CMTime(seconds: 1.0 / 10.0, preferredTimescale: VCTimeControl.timeBase)
            
        case 9000..<12000:
            intervalTime = CMTime(seconds: 1.0 / 15.0, preferredTimescale: VCTimeControl.timeBase)
            
        default:
            break
        }
        widthPerTimeVale = scale * 1 / 6 / 600
        widthPerBaseValue = widthPerTimeVale * CGFloat(intervalTime.value)
    }
    
}
