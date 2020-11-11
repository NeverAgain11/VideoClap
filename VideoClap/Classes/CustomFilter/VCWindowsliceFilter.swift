//
//  VCWindowsliceFilter.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/5.
//

import AVFoundation
import CoreImage

open class VCWindowsliceFilter: CIFilter {
    
    private static let sourceCode = """

    kernel vec4 transition(sampler inputImage, sampler inputTargetImage, float iTime, float count, float smoothness) {
        vec2 p = samplerCoord(inputImage);
        
        float pr = smoothstep(-smoothness, 0.0, p.x - iTime * (1.0 + smoothness));
        float s = step(pr, fract(count * p.x));
        
        vec4 texture0Color = sample(inputImage, samplerCoord(inputImage));
        vec4 texture1Color = sample(inputTargetImage, samplerCoord(inputTargetImage));
        
        return mix(texture0Color, texture1Color, s);
    }

    """
    
    private static let kernel: CIKernel? = {
        return CIKernel(source: sourceCode)
    }()
    
    @objc public var inputImage: CIImage?
    
    @objc public var inputTargetImage: CIImage?
    
    @objc public var inputTime: NSNumber = 1.0
    
    @objc public var count: NSNumber = 10.0
    
    @objc public var smoothness: NSNumber = 1.0
    
    public override var outputImage: CIImage? {
        guard let kernel = VCWindowsliceFilter.kernel else { return nil }
        guard let inputImage = self.inputImage else { return nil }
        guard let inputTargetImage = self.inputTargetImage else { return nil }
        var finalFrame: CIImage = inputImage
        
        finalFrame = kernel.apply(extent: finalFrame.extent, roiCallback: { (index, destRect) -> CGRect in
            return destRect
        }, arguments: [finalFrame, inputTargetImage, inputTime.floatValue, count.floatValue, smoothness.floatValue]) ?? finalFrame
        
        return finalFrame
    }
    
}
