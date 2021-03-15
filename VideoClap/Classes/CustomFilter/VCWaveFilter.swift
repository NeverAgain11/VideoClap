//
//  VCWaveFilter.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/2.
//

import Foundation
import CoreImage

open class VCWaveFilter: CIFilter {
    
    private static let sourceCode = """
    kernel vec4 main(sampler inputImage, sampler inputTargetImage, float iTime, float2 renderSize, float amplitude, float angularVelocity, float frequency) {
        vec2 dc = destCoord();
        vec2 uv = dc / renderSize;
        vec2 uv0 = samplerTransform(inputImage, dc);
        vec2 uv1 = samplerTransform(inputTargetImage, dc);

        vec4 texture0Color = sample(inputImage, uv0);
        vec4 texture1Color = sample(inputTargetImage, uv1);

        float initialPhase = frequency * cos(iTime);
        float offset = sin(iTime);
        float y = amplitude * sin((angularVelocity * uv.x) + initialPhase) + offset;
        
        y = y * 1.3;

        vec4 color = uv.y > y ? texture0Color : texture1Color;

        return color;
    }
    """
    
    private static let kernel: CIKernel? = {
        return CIKernel(source: sourceCode)
    }()
    
    @objc public var inputImage: CIImage?
    
    @objc public var inputTargetImage: CIImage?
    
    @objc public var inputTime: NSNumber = 1.0
    
    @objc public var renderSize: CIVector = CIVector(x: 0.0, y: 0.0)
    
    @objc public var amplitude: NSNumber = NSNumber(value: 0.05)
    
    @objc public var angularVelocity: NSNumber = NSNumber(value: 10.0)
    
    @objc public var frequency: NSNumber = NSNumber(value: 10.0)
    
    public override var outputImage: CIImage? {
        guard let kernel = VCWaveFilter.kernel else { return nil }
        guard let inputImage = self.inputImage else { return nil }
        guard let inputTargetImage = self.inputTargetImage else { return nil }
        var finalFrame: CIImage = inputImage
        
        finalFrame = kernel.apply(extent: finalFrame.extent, roiCallback: { (index, destRect) -> CGRect in
            return destRect
        }, arguments: [finalFrame, inputTargetImage, inputTime.floatValue, renderSize, amplitude.floatValue, angularVelocity.floatValue, frequency.floatValue]) ?? finalFrame
        
        return finalFrame
    }
    
}
