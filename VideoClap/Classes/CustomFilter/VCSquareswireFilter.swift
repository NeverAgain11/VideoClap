//
//  VCSquareswireFilter.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/5.
//

import Foundation
import AVFoundation
import CoreImage

open class VCSquareswireFilter: CIFilter {
    
    private static let sourceCode = """

    kernel vec4 transition(sampler inputImage, sampler inputTargetImage, float progress, vec2 squares, vec2 direction, float smoothness) {
        vec2 center = vec2(0.5, 0.5);
        vec2 p = samplerCoord(inputImage);
        vec2 p1 = samplerCoord(inputTargetImage);
        vec2 v = normalize(direction);
        v /= abs(v.x)+abs(v.y);
        float d = v.x * center.x + v.y * center.y;
        float offset = smoothness;
        float pr = smoothstep(-offset, 0.0, v.x * p.x + v.y * p.y - (d-0.5+progress*(1.+offset)));
        vec2 squarep = fract(p*vec2(squares));
        vec2 squaremin = vec2(pr/2.0);
        vec2 squaremax = vec2(1.0 - pr/2.0);
        float a = (1.0 - step(progress, 0.0)) * step(squaremin.x, squarep.x) * step(squaremin.y, squarep.y) * step(squarep.x, squaremax.x) * step(squarep.y, squaremax.y);
        return mix(sample(inputImage, p), sample(inputTargetImage, p1), a);
    }

    """
    
    private static let kernel: CIKernel? = {
        return CIKernel(source: sourceCode)
    }()
    
    @objc public var inputImage: CIImage?
    
    @objc public var inputTargetImage: CIImage?
    
    @objc public var inputTime: NSNumber = 1.0
    
    @objc public var squares: CIVector = CIVector(x: 10, y: 10)
    
    @objc public var direction: CIVector = CIVector(x: 1.0, y: -0.5)
    
    @objc public var smoothness: NSNumber = 1.6
    
    public override var outputImage: CIImage? {
        guard let kernel = VCSquareswireFilter.kernel else { return nil }
        guard let inputImage = self.inputImage else { return nil }
        guard let inputTargetImage = self.inputTargetImage else { return nil }
        var finalFrame: CIImage = inputImage
        
        finalFrame = kernel.apply(extent: finalFrame.extent, roiCallback: { (index, destRect) -> CGRect in
            return destRect
        }, arguments: [finalFrame, inputTargetImage, inputTime.floatValue, squares, direction, smoothness]) ?? finalFrame
        
        return finalFrame
    }
    
}
