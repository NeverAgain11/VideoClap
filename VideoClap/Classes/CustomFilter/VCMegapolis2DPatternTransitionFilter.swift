//
//  VCMegapolis2DPatternTransitionFilter.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/12.
//

import Foundation
import AVFoundation
import CoreImage

open class VCMegapolis2DPatternTransitionFilter: CIFilter {
    
    private static let sourceCode = """
    
    #define TIME_MULT 0.25
    #define IDLE_TIME 0.05

    #define rnd(p) fract(sin(dot(p, vec2(12.9898,78.233))) * 43758.5453123)

    kernel vec4 transition( sampler inputImage, sampler inputTargetImage, float progress, vec2 iResolution ) {
        vec4 O = vec4(0.0);
        float iTime = progress * 3.5;

        vec2 U = vec2(iResolution.x * samplerCoord(inputImage).x, iResolution.y * samplerCoord(inputImage).y);

        vec2 uv = U.xy / iResolution.xy;
        
        

        vec4 color0 = sample(inputImage, uv);
        vec4 color1 = sample(inputTargetImage, uv);
        
        vec2 uv = U.xy / iResolution.xy;
        
        vec2 R  = iResolution.xy;
        float p = 6./R.y;
        U *= p;
         
        
        float t = fract(iTime * TIME_MULT),
             mt = ceil(iTime * TIME_MULT),
            cellStartTime = rnd(ceil(U) * mt) * .5 + IDLE_TIME,
              w = .25 + .75* smoothstep(0., .175, t-cellStartTime-.225);

        if (t > cellStartTime)
            U = smoothstep(p,0.,abs(fract(U)-.5) - w/2. ),
            O += U.x*U.y;
        
        return mix(color0, color1, O.x);
        
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
        guard let kernel = VCMegapolis2DPatternTransitionFilter.kernel else { return nil }
        guard let inputImage = self.inputImage else { return nil }
        guard let inputTargetImage = self.inputTargetImage else { return nil }
        var finalFrame: CIImage = inputImage
        
        let image = kernel.apply(extent: finalFrame.extent, roiCallback: { (index, destRect) -> CGRect in    
            return destRect
        }, arguments: [finalFrame, inputTargetImage, inputTime.floatValue, inputResolution])
        
        return image
    }
    
}
