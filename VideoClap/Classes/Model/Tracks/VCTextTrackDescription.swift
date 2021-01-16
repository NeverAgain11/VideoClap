//
//  VCTextTrackDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/3.
//

import AVFoundation

public class VCTextTrackDescription: VCImageTrackDescription {
    
    public var text: NSAttributedString = NSAttributedString(string: "")
    
    public var center: CGPoint {
        get {
            switch imageLayout {
            case .fit:
                return .zero
            case .fill:
                return .zero
            case .center(let point):
                return point
            case .rect(_):
                return .zero
            }
        }
        set {
            imageLayout = .center(newValue)
        }
    }
    
    public var isTypewriter: Bool = false
    
    public override func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCTextTrackDescription()
        copyObj.mediaURL         = mediaURL
        copyObj.id               = id
        copyObj.timeRange        = timeRange
        copyObj.isFit            = isFit
        copyObj.isFlipHorizontal = isFlipHorizontal
        copyObj.filterIntensity  = filterIntensity
        copyObj.lutImageURL      = lutImageURL
        copyObj.rotateRadian     = rotateRadian
        copyObj.cropedRect       = cropedRect
        copyObj.trajectory       = trajectory
        copyObj.canvasStyle      = canvasStyle
        copyObj.imageLayout      = imageLayout
        copyObj.indexPath        = indexPath
        copyObj.text             = text.mutableCopy() as! NSAttributedString
        copyObj.center           = center
        copyObj.isTypewriter     = isTypewriter
        return copyObj
    }
    
    public override func originImage(time: CMTime, renderSize: CGSize, renderScale: CGFloat, compensateTimeRange: CMTimeRange?) -> CIImage? {
        locker.object(forKey: #function).lock()
        defer {
            locker.object(forKey: #function).unlock()
        }
        var renderText: NSAttributedString?
        if isTypewriter {
            let progress = (time.seconds / timeRange.duration.seconds).clamped(to: 0...1.0)
            if progress.isNaN == false && progress.isInfinite == false {
                renderText = text.attributedSubstring(from: NSRange(location: 0, length: Int(ceil(Double(text.length) * progress))))
            }
        } else {
            renderText = text
        }
        
        if let renderText = renderText {
            let renderer = VCGraphicsRenderer()
            renderer.rendererRect.size = text.size()
            return renderer.ciImage { (context: CGContext) in
                renderText.draw(in: renderer.rendererRect)
            }
        } else {
            return nil
        }
    }
    
}
