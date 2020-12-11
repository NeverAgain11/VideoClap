//
//  VCBounceTransitionFilter.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/13.
//

import AVFoundation
import CoreImage

open class VCBounceTransitionFilter: CIFilter {
    
    private static let sourceCode = """

    float f1(float x)
    {
       return abs(sin(x * 3.0));
    }
        
    float f2(float x, float bounce)
    {
       return pow(x, 2.0) * bounce;
    }
        
    float f3(float x, float bounce)
    {
        return f2(x / 10.0, bounce) * f1(x);
    }

    kernel vec4 mainImage( sampler inputImage, sampler inputTargetImage, float iTime , float bounce)
    {
        
        vec4 black = vec4(0.0, 0.0, 0.0, 1.0);
        
        float progress = iTime;
        
        vec2 uv = samplerCoord(inputImage);
        
        float offsety = f3((1.0 - progress) * -5.0, bounce);
                
        vec4 color0 = sample(inputImage, samplerCoord(inputImage));
        vec2 pos = vec2(samplerCoord(inputTargetImage).x + progress - 1.0, samplerCoord(inputTargetImage).y - offsety);
        vec4 color1 = sample(inputTargetImage, pos);
        
        color1 = mix(color0, color1, step(offsety, samplerCoord(inputTargetImage).y));
        
        vec3 color = vec3(mix(color0, color1, step((1.0 - progress), uv.x)));
        
        return vec4(color, 1.0);
    }

    """
    
    private static let kernel: CIKernel? = {
        return CIKernel(source: sourceCode)
    }()
    
    @objc public var inputImage: CIImage?
    
    @objc public var inputTargetImage: CIImage?
    
    @objc public var inputTime: NSNumber = 1.0
    
    @objc public var bounce: NSNumber = 3.2
    
    public override var outputImage: CIImage? {
        guard let kernel = VCBounceTransitionFilter.kernel else { return nil }
        guard let inputImage = self.inputImage else { return nil }
        guard let inputTargetImage = self.inputTargetImage else { return nil }
        var finalFrame: CIImage = inputImage
        
        finalFrame = kernel.apply(extent: finalFrame.extent, roiCallback: { (index, destRect) -> CGRect in
            return index == 0 ? inputImage.extent : destRect
        }, arguments: [finalFrame, inputTargetImage, inputTime.floatValue, bounce.floatValue]) ?? finalFrame
        
        return finalFrame
    }
    
}
