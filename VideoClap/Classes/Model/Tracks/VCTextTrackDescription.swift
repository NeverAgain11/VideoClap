//
//  VCTextTrackDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/3.
//

import AVFoundation

public class VCTextTrackDescription: VCImageTrackDescription {
    
    public var text = NSMutableAttributedString(string: "")
    
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
    
    public var textEffectProvider: VCTextEffectProviderProtocol?
    
    internal var context = VCTextEffectRenderContext()
    
    public override func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCTextTrackDescription()
        copyObj.mediaURL           = mediaURL
        copyObj.id                 = id
        copyObj.timeRange          = timeRange
        copyObj.isFlipHorizontal   = isFlipHorizontal
        copyObj.filterIntensity    = filterIntensity
        copyObj.lutImageURL        = lutImageURL
        copyObj.rotateRadian       = rotateRadian
        copyObj.cropedRect         = cropedRect
        copyObj.trajectory         = trajectory
        copyObj.canvasStyle        = canvasStyle
        copyObj.imageLayout        = imageLayout
        copyObj.indexPath          = indexPath
        copyObj.text               = text.mutableCopy() as! NSMutableAttributedString
        copyObj.center             = center
        copyObj.textEffectProvider = textEffectProvider
        return copyObj
    }
    
    public override func prepare(description: VCVideoDescription) {
        super.prepare(description: description)
        if textEffectProvider != nil {
            context.text = text
            context.renderSize = description.renderSize
            context.renderScale = description.renderScale
            context.textSize = text.size()
            
            let framesetter = SCTFramesetter(attrString: text)
            let sctFrame = framesetter.createFrame()
            context.characters = sctFrame.characters()
        }
    }
    
    public override func originImage(time: CMTime, compensateTimeRange: CMTimeRange?) -> CIImage? {
        return originImage(time: time, renderSize: .zero, renderScale: 0.0, compensateTimeRange: compensateTimeRange)
    }
    
    public override func originImage(time: CMTime, renderSize: CGSize, renderScale: CGFloat, compensateTimeRange: CMTimeRange?) -> CIImage? {
        locker.object(forKey: #function).lock()
        defer {
            locker.object(forKey: #function).unlock()
        }
        
        if let effectProvider = self.textEffectProvider {
            let progress = (time.seconds / timeRange.duration.seconds).clamped(to: 0...1.0)
            context.progress = CGFloat(progress)
            return effectProvider.effectImage(context: context)
        } else {
            let renderer = VCGraphicsRenderer()
            renderer.rendererRect.size = text.size()
            
            return renderer.ciImage { (context) in
                text.draw(at: .zero)
            }
        }
    }
    
}
