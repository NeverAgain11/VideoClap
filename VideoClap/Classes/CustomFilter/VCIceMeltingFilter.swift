//
//  VCIceMeltingFilter.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/3.
//

import AVFoundation
import CoreImage

open class VCIcebreakerFilter: CIFilter {
    
    private static let sourceCode = """
    // https://www.shadertoy.com/view/ll3SD2
    // Created by Hadyn
    #define PHASE_POWER 2.0
    #define PHI 1.61803398874989484820459

    float gold_noise(vec2 xy, float seed) {
        return fract(tan(distance(xy * PHI, xy) * seed) * xy.x);
    }

    vec2 hash2( vec2 p )
    {
        return vec2(gold_noise(p, 9.0), gold_noise(p, 2.0));
    }

    vec4 voronoi( vec2 x )
    {
        vec2 n = floor(x);
        vec2 f = fract(x);
        vec2 o;

        vec2 mg, mr;
        float oldDist;
        
        float md = 8.0;
        for( int j=-1; j<=1; j++ )
        {
            for( int i=-1; i<=1; i++ )
            {
                vec2 g = vec2(float(i),float(j));
                o = hash2( n + g );
                vec2 r = g + o - f;
                float d = dot(r,r);
                
                if( d<md )
                {
                    md = d;
                    mr = r;
                    mg = g;
                }
            }
        }
        
        oldDist = md;
        
        md = 8.0;
        for( int j=-2; j<=2; j++ )
        {
            for( int i=-2; i<=2; i++ )
            {
                vec2 g = mg + vec2(float(i),float(j));
                o = hash2( n + g );
                vec2 r = g + o - f;
                
                if( dot(mr-r,mr-r)>0.00001 )
                md = min( md, dot( 0.5*(mr+r), normalize(r-mr) ) );
            }
        }
        
        return vec4( md, mr, oldDist );
    }

    kernel vec4 transition(sampler inputImage, sampler inputTargetImage, float iTime) {
        vec2 uv = samplerCoord(inputImage);
        
        float progress = iTime;
        vec4  fragColor = vec4(1.0);
        float timeStep = progress*0.59;
        
        vec2 p = uv;
        p *= 6.1;
        p.x += timeStep*6.0;
        p.y += timeStep*3.0;
        
        vec4 c = voronoi( p );
        c.x = 1.0-pow(1.0-c.x, 2.0);
        
        float cellPhase = p.x + c.y + 2.0*sin((p.y + c.z)*0.8 + (p.x + c.y)*0.4);
        cellPhase *= 0.025;
        cellPhase = clamp(abs(mod(cellPhase -timeStep, 1.0)-0.5)*2.0, 0.0, 1.0);
        cellPhase = pow(clamp(cellPhase*2.0-0.5, 0.0, 1.0), PHASE_POWER);
        
        float edgePhase = p.x + 2.0*sin(p.y*0.8 + p.x*0.4);
        edgePhase *= 0.025;
        edgePhase = clamp(abs(mod(edgePhase -timeStep, 1.0)-0.5)*2.0, 0.0, 1.0);
        edgePhase = pow(clamp(edgePhase*2.0-0.5, 0.0, 1.0), PHASE_POWER);
        
        float phase = mix(edgePhase, cellPhase, smoothstep(0.0,0.2, edgePhase));
        
        vec4 color1 = sample(inputTargetImage, samplerCoord(inputTargetImage));
        vec4 color0 = sample(inputImage, samplerCoord(inputImage));
        
        vec3 col = mix( color0.xyz, color1.xyz, smoothstep( phase-0.025, phase, c.x ) );

        fragColor = vec4(col,1.0);
        return fragColor;
    }

    """
    
    private static let kernel: CIKernel? = {
        return CIKernel(source: sourceCode)
    }()
    
    @objc public var inputImage: CIImage?
    
    @objc public var inputTargetImage: CIImage?
    
    @objc public var inputTime: NSNumber = 1.0
    
    public override var outputImage: CIImage? {
        guard let kernel = VCIcebreakerFilter.kernel else { return nil }
        guard let inputImage = self.inputImage else { return nil }
        guard let inputTargetImage = self.inputTargetImage else { return nil }
        var finalFrame: CIImage = inputImage
        
        finalFrame = kernel.apply(extent: finalFrame.extent, roiCallback: { (index, destRect) -> CGRect in
            return destRect
        }, arguments: [finalFrame, inputTargetImage, inputTime.floatValue]) ?? finalFrame
        
        return finalFrame
    }
    
}
