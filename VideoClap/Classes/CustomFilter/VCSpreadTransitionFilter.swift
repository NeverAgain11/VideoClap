//
//  VCSpreadTransitionFilter.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/13.
//

import Foundation
import AVFoundation
import CoreImage

open class VCSpreadTransitionFilter: CIFilter {
    
    private static let sourceCode = """

    float snoise(vec3 uv, float res) {
        const vec3 s = vec3(1e0, 1e2, 1e3);
        
        uv *= res;
        
        vec3 uv0 = floor(mod(uv, res))*s;
        vec3 uv1 = floor(mod(uv+vec3(1.), res))*s;
        
        vec3 f = fract(uv); f = f*f*(3.0-2.0*f);
        
        vec4 v = vec4(uv0.x+uv0.y+uv0.z, uv1.x+uv0.y+uv0.z,
                      uv0.x+uv1.y+uv0.z, uv1.x+uv1.y+uv0.z);
        
        vec4 r = fract(sin(v*1e-1)*1e3);
        float r0 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
        
        r = fract(sin((v + uv1.z - uv0.z)*1e-1)*1e3);
        float r1 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
        
        return mix(r0, r1, f.z)*2.-1.;
    }

    kernel vec4 transition( sampler inputImage, sampler inputTargetImage, float iTime, vec2 iResolution ) {
        vec2 fragCoord = vec2(iResolution.x * samplerCoord(inputImage).x, iResolution.y * samplerCoord(inputImage).y);
        
        vec2 p = -.5 + fragCoord.xy / iResolution.xy;
        p.x *= iResolution.x/iResolution.y;
        
        float color = 4.47281 * iTime * 1.35 * iResolution.x / iResolution.y - (3.*length(2.*p));
        
        vec3 coord = vec3(atan(p.x,p.y)/6.2832+.5, length(p)*.4, .5);
        
        for(int i = 1; i <= 7; i++)
        {
            float power = pow(2.0, float(i));
            color += (1.5 / power) * snoise(coord + vec3(0.,-iTime*.05, iTime*.01), power*16.);
        }
        vec4 fragColor = vec4( color, pow(max(color,0.),2.)*0.4, pow(max(color,0.),3.)*0.15 , 1.0);
        
        vec4 color0 = sample(inputImage, samplerCoord(inputImage));
        vec4 color1 = sample(inputTargetImage, samplerCoord(inputTargetImage));
        
        fragColor = mix(color0, color1, step(0.5, fragColor.x));

        return fragColor;
    }

    """
    
    private static let kernel: CIKernel? = {
        return CIKernel(source: sourceCode)
    }()
    
    @objc public var inputImage: CIImage?
    
    @objc public var inputTargetImage: CIImage?
    
    @objc public var inputTime: NSNumber = 1.0
    
    @objc public var inputResolution: CIVector = CIVector(x: 0.0, y: 0.0)
    
    public override var outputImage: CIImage? {
        guard let kernel = VCSpreadTransitionFilter.kernel else { return nil }
        guard let inputImage = self.inputImage else { return nil }
        guard let inputTargetImage = self.inputTargetImage else { return nil }
        var finalFrame: CIImage = inputImage
        
        let image = kernel.apply(extent: finalFrame.extent, roiCallback: { (index, destRect) -> CGRect in
            return destRect
        }, arguments: [finalFrame, inputTargetImage, inputTime.floatValue, inputResolution])
        
        return image
    }
    
}
