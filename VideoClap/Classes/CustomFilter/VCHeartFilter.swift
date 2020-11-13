//
//  VCHeartFilter.swift
//  VideoClap
//
//  Created by laimincong on 2020/11/12.
//


import AVFoundation
import CoreImage

open class VCHeartFilter: CIFilter {
    
    private static let sourceCode = """

    float inHeart (vec2 p, vec2 center, float size) {
        if (size==0.0) return 0.0;
        vec2 o = (p-center)/(1.6*size);
        float a = o.x*o.x+o.y*o.y-0.3;
        return step(a*a*a, o.x*o.x*o.y*o.y*o.y);
    }

    kernel vec4 transition (sampler inputImage, sampler inputTargetImage, float progress) {
        vec2 uv0 = samplerCoord(inputImage);
        vec2 uv1 = samplerCoord(inputTargetImage);


        vec4 texture0Color = sample(inputImage, uv0);
        vec4 texture1Color = sample(inputTargetImage, uv1);

        return mix(
            texture0Color,
            texture1Color,
            inHeart(uv0, vec2(0.5, 0.4), progress)
        );
    }

    """
    
    private static let kernel: CIKernel? = {
        return CIKernel(source: sourceCode)
    }()
    
    @objc public var inputImage: CIImage?
    
    @objc public var inputTargetImage: CIImage?
    
    @objc public var inputTime: NSNumber = 1.0
    
    public override var outputImage: CIImage? {
        guard let kernel = VCHeartFilter.kernel else { return nil }
        guard let inputImage = self.inputImage else { return nil }
        guard let inputTargetImage = self.inputTargetImage else { return nil }
        var finalFrame: CIImage = inputImage
        
        finalFrame = kernel.apply(extent: finalFrame.extent, roiCallback: { (index, destRect) -> CGRect in
            return destRect
        }, arguments: [finalFrame, inputTargetImage, inputTime.floatValue]) ?? finalFrame
        
        return finalFrame
    }
    
}