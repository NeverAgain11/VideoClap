//
//  VCWaveFilter.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/2.
//

import Foundation
import CoreImage

open class VCWaveFilter: CIFilter {
    
    private let sourceCode = """
    kernel vec4 YasicLUT(sampler inputImage, sampler inputTargetImage, float iTime) {
        vec2 uv =  samplerCoord(inputImage);
        vec4 texture0Color = sample(inputImage, samplerCoord(inputImage));
        vec4 texture1Color = sample(inputTargetImage, samplerCoord(inputTargetImage));

        float amplitude = 0.05;
        float angularVelocity = 10.0;
        float frequency = 10.0;
        float initialPhase = frequency * cos(iTime);
        float offset = sin(iTime);
        float y = amplitude * sin((angularVelocity * uv.x) + initialPhase) + offset;
        
        y = y * 1.3;

        vec4 color = uv.y > y ? texture0Color : texture1Color;

        return color;
    }
    """
    
    private lazy var waveKernel: CIKernel? = {
        return CIKernel(source: sourceCode)
    }()
    
    @objc public var inputImage: CIImage?
    
    @objc public var inputTargetImage: CIImage?
    
    @objc public var inputTime: NSNumber = 1.0
    
    public override var outputImage: CIImage? {
        guard let kernel = waveKernel else { return nil }
        guard let inputImage = self.inputImage else { return nil }
        guard let inputTargetImage = self.inputTargetImage else { return nil }
        var finalFrame: CIImage = inputImage
        
        finalFrame = kernel.apply(extent: finalFrame.extent, roiCallback: { (index, destRect) -> CGRect in
            return destRect
        }, arguments: [finalFrame, inputTargetImage, inputTime.floatValue]) ?? finalFrame
        
        return finalFrame
    }
    
}
