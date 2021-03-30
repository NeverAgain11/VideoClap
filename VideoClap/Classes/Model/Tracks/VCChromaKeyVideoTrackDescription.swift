//
//  VCChromaKeyVideoTrackDescription.swift
//  VideoClap
//
//  Created by lai001 on 2021/3/27.
//

import AVFoundation

public enum ChromaKeyType {
    case hue(VCRange)
    case brightness(VCRange)
}

public class VCChromaKeyVideoTrackDescription: VCVideoTrackDescription {
    
    var hueFilter = VCHelper.chromaKeyFilter(fromHue: 0.3, toHue: 0.4)
    
    var brightnessFilter = VCHelper.chromaKeyFilter(fromBrightness: 0.0, toBrightness: 0.05)
    
    public var keyType: ChromaKeyType = .hue(VCRange(left: 0.3, right: 0.4)) {
        didSet {
            switch keyType {
            case .hue(let range):
                hueFilter = VCHelper.chromaKeyFilter(fromHue: CGFloat(range.left), toHue: CGFloat(range.right))
                brightnessFilter = nil
            case .brightness(let range):
                hueFilter = nil
                brightnessFilter = VCHelper.chromaKeyFilter(fromBrightness: CGFloat(range.left), toBrightness: CGFloat(range.right))
            }
        }
    }
    
    public override func compositionImage(sourceFrame: CIImage, compositionTime: CMTime, renderSize: CGSize, renderScale: CGFloat, compensateTimeRange: CMTimeRange?) -> CIImage? {
        let _compositionImage = super.compositionImage(sourceFrame: sourceFrame, compositionTime: compositionTime, renderSize: renderSize, renderScale: renderScale, compensateTimeRange: compensateTimeRange)
        let filter = hueFilter ?? brightnessFilter
        filter?.setValue(_compositionImage, forKey: kCIInputImageKey)
        return filter?.outputImage
    }
    
}
