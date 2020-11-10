//
//  VCDropletsFilter .swift
//  VideoClap
//
//  Created by lai001 on 2020/11/5.
//

import Foundation
import CoreImage

open class VCDropletsFilter: CIFilter {
    
    /// https://www.shadertoy.com/view/ltlSzl
    private let sourceCode = """
    
    #define NUM 100

    float rand(float x)
    {
        return fract(sin(x * 154.4514) * 72561.556);
    }

    float rand(vec2 x)
    {
        return rand(dot(x, vec2(11.4935, 17.5183)));
    }

    float circle(vec2 uv, vec2 pos, float rad)
    {
        return length(pos - uv) - rad;
    }

    vec3 normal(vec2 uv, vec2 pos, float rad)
    {
        vec2 d = pos - uv;
        float x = length(d);
        float z = 1. - pow(x / rad, 5.0);
        return normalize(vec3(d, z));
    }

    kernel vec4 YasicLUT(sampler inputImage, float iTime) {
        vec4 fragColor = vec4(0.0, 0.0, 0.0, 0.0);
    
        vec2 uv = samplerCoord(inputImage);
        uv.y = 1.0 - uv.y;
        vec2 uvFoa = uv * 2.0 - 1.0;
        uv = samplerCoord(inputImage);
        vec3 color = sample(inputImage, uv).rgb;
    
        float aspect = samplerSize(inputImage).x / samplerSize(inputImage).y
        uvFoa.x *= aspect;
        
        for (int i=0; i<NUM; i++)
        {
            
            vec2 pos = vec2(-1, -1) + vec2(2, 2) * vec2(rand(float(i)+234.230), rand(float(i)+173.1523));
            pos.x *= aspect;
            pos.y += iTime * (0.1 + 0.1 * rand(float(float(i)*34.35)));
            pos.y = mod(pos.y + 1.0, 2.0) - 1.0;
            float rad = 0.02 + 0.1 * rand(float(i));
            pos.y = pos.y * (1.0 + 2.0 * rad) - rad; // avoid popping
            
            float d = circle(uvFoa, pos, rad);
            if (d <= 0.)
            {
                vec2 n = normal(uvFoa, pos, rad).xy;
                vec2 uv2 = uv + n * 2.;
                
                vec3 drop = sample(inputImage, uv2).rgb;
                float alpha = smoothstep(0., -0.02, d); // smooth edges
                color = mix(color, drop, alpha);
            }
        }

        fragColor = vec4(color, 1.0);

        return fragColor;
    }
    """
    
    private lazy var waveKernel: CIKernel? = {
        return CIKernel(source: sourceCode)
    }()
    
    @objc public var inputImage: CIImage?
    
    @objc public var inputTime: NSNumber = 1.0
    
    public override var outputImage: CIImage? {
        guard let kernel = waveKernel else { return nil }
        guard let inputImage = self.inputImage else { return nil }
        var finalFrame: CIImage = inputImage
        let aspectLength = max(inputImage.extent.size.width, inputImage.extent.size.height)
        let outputImageExtent = CGRect(origin: .zero, size: CGSize(width: aspectLength, height: aspectLength))
        finalFrame = kernel.apply(extent: outputImageExtent, roiCallback: { (index, destRect) -> CGRect in
            return destRect
        }, arguments: [finalFrame, inputTime.floatValue]) ?? finalFrame
        
        return finalFrame
    }
    
}
