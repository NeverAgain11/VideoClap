//
//  VCCubeFilter.swift
//  VideoClap
//
//  Created by laimincong on 2020/11/11.
//

import Foundation
import AVFoundation
import CoreImage

open class VCCubeFilter: CIFilter {
    
    private static let sourceCode = """

    vec4 getColor(sampler image, vec2 coord) {
        return sample(image, coord);
    }

    vec2 project (vec2 p, float floating) {
        return p * vec2(1.0, -1.2) + vec2(0.0, -floating/100.);
    }

    bool inBounds (vec2 p) {
        return all(lessThan(vec2(0.0), p)) && all(lessThan(p, vec2(1.0)));
    }

    vec4 bgColor (vec2 p, vec2 pfr, vec2 pto, sampler inputImage, sampler inputTargetImage, float reflection, float floating) {
        vec4 c = vec4(0.0, 0.0, 0.0, 1.0);
        pfr = project(pfr, floating);
        
        if (inBounds(pfr)) {
            c += mix(vec4(0.0), getColor(inputImage, pfr), reflection * mix(1.0, 0.0, pfr.y));
        }
        pto = project(pto, floating);
        if (inBounds(pto)) {
            c += mix(vec4(0.0), getColor(inputTargetImage, pto), reflection * mix(1.0, 0.0, pto.y));
        }
        return c;
    }

    vec2 xskew (vec2 p, float persp, float center) {
        float x = mix(p.x, 1.0-p.x, center);
        return (
            (
                vec2( x, (p.y - 0.5*(1.0-persp) * x) / (1.0+(persp-1.0)*x) )
                    - vec2(0.5-abs(center - 0.5), 0.0)
            )
            * vec2(0.5 / abs(center - 0.5) * (center<0.5 ? 1.0 : -1.0), 1.0)
            + vec2(center<0.5 ? 0.0 : 1.0, 0.0)
        );
    }

    kernel vec4 transition(sampler inputImage, sampler inputTargetImage, float progress, float persp, float unzoom, float reflection, float floating) {
        vec2 op = samplerCoord(inputImage);
        vec2 op2 = samplerCoord(inputTargetImage);

        float uz = unzoom * 2.0*(0.5-abs(0.5 - progress));

        vec2 p = -uz*0.5+(1.0+uz) * op;
        vec2 p2 = -uz*0.5+(1.0+uz) * op2;
        
        vec2 fromP = xskew(
            (p - vec2(progress, 0.0)) / vec2(1.0-progress, 1.0),
            1.0-mix(progress, 0.0, persp),
            0.0
        );

        vec2 toP = xskew(
            p2 / vec2(progress, 1.0),
            mix(pow(progress, 2.0), 1.0, persp),
            1.0
        );
        
        if (inBounds(fromP)) {
            return getColor(inputImage, fromP);
        }
        else if (inBounds(toP)) {
            return getColor(inputTargetImage, toP);
        }
        return vec4(0.0, 0.0, 0.0, 1.0); // FIXME: 返回黑色，暂时修复显示图像异常
        return bgColor(op, fromP, toP, inputImage, inputTargetImage, reflection, floating);
    }

    """
    
    private static let kernel: CIKernel? = {
        return CIKernel(source: sourceCode)
    }()
    
    @objc public var inputImage: CIImage?
    
    @objc public var inputTargetImage: CIImage?
    
    @objc public var inputTime: NSNumber = 1.0
    
    @objc public var persp: NSNumber = 0.7
    
    @objc public var unzoom: NSNumber = 0.3
    
    @objc public var reflection: NSNumber = 0.4
    
    @objc public var floating: NSNumber = 3.0
    
    public override var outputImage: CIImage? {
        guard let kernel = VCCubeFilter.kernel else { return nil }
        guard let inputImage = self.inputImage else { return nil }
        guard let inputTargetImage = self.inputTargetImage else { return nil }
        var finalFrame: CIImage = inputImage
        let aspectLength = max(inputImage.extent.size.width, inputImage.extent.size.height, inputTargetImage.extent.size.width, inputTargetImage.extent.size.height)
        let outputImageExtent = CGRect(origin: .zero, size: CGSize(width: aspectLength, height: aspectLength))
        finalFrame = kernel.apply(extent: outputImageExtent, roiCallback: { (index, destRect) -> CGRect in
            return index == 0 ? inputImage.extent : destRect
        }, arguments: [finalFrame, inputTargetImage, inputTime.floatValue, persp.floatValue, unzoom.floatValue, reflection.floatValue, floating.floatValue]) ?? finalFrame
        return finalFrame
    }
    
}
