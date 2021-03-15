//
//  VCHeartFilter.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/12.
//

import AVFoundation
import CoreImage

open class VCHeartFilter: CIFilter {
    
    private static let sourceCode = """

    float inHeart (vec2 p, vec2 center, float size, float2 renderSize) {
        if (size==0.0) return 0.0;
        float ratio = renderSize.x / renderSize.y;

        vec2 o = (p-center)/(1.6*size);
        o.x *= ratio;
        
        float a = o.x*o.x+o.y*o.y - 0.3;
        return step(a*a*a, o.x*o.x*o.y*o.y*o.y);
    }

    kernel vec4 transition (sampler inputImage, sampler inputTargetImage, float progress, float2 renderSize) {
        vec2 dc = destCoord();
        vec2 uv0 = samplerTransform(inputImage, dc);
        vec2 uv1 = samplerTransform(inputTargetImage, dc);

        vec4 texture0Color = sample(inputImage, uv0);
        vec4 texture1Color = sample(inputTargetImage, uv1);
        
        return mix(
            texture0Color,
            texture1Color,
            inHeart(dc / renderSize, vec2(0.5, 0.4), progress, renderSize)
        );
    }

    """
    
    private static let kernel: CIKernel? = {
        let ker = CIKernel(source: sourceCode)
        
        return CIKernel(source: sourceCode)
    }()
    
    @objc public var inputImage: CIImage?
    
    @objc public var inputTargetImage: CIImage?
    
    @objc public var inputTime: NSNumber = 1.0
    
    @objc public var renderSize: CIVector = CIVector(x: 0.0, y: 0.0)
    
    public override var outputImage: CIImage? {
        guard let kernel = VCHeartFilter.kernel else { return nil }
        guard let inputImage = self.inputImage else { return nil }
        guard let inputTargetImage = self.inputTargetImage else { return nil }
        var finalFrame: CIImage = inputImage
        
        finalFrame = kernel.apply(extent: finalFrame.extent, roiCallback: { (index, destRect) -> CGRect in
            return destRect
        }, arguments: [finalFrame, inputTargetImage, inputTime.floatValue, renderSize]) ?? finalFrame
        
        return finalFrame
    }
    
}
