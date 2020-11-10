//
//  VCDoorwayFilter.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/5.
//

import Foundation
import CoreImage

open class VCDoorwayFilter: CIFilter {
    
    private let sourceCode = """
    #define black vec4(0.0, 0.0, 0.0, 1.0)
    #define boundMin vec2(0.0, 0.0)
    #define boundMax vec2(1.0, 1.0)

    bool inBounds (vec2 p) {
        return all(lessThan(boundMin, p)) && all(lessThan(p, boundMax));
    }

    vec2 project (vec2 p) {
        return p * vec2(1.0, -1.2) + vec2(0.0, -0.02);
    }

    vec4 bgColor (vec2 p, vec2 pto, float reflection, sampler inputTargetImage, float progress) {
        vec4 c = black;
        pto = project(pto);
        if (inBounds(pto)) {
            c += mix(black, sample(inputTargetImage, pto), reflection * mix(1.0, 0.0, pto.y) * (1.0 - progress));
        }
        return c;
    }

    vec4 getColor(sampler image)
    {
        return sample(image, samplerCoord(image));
    }

    kernel vec4 transition (sampler inputImage, sampler inputTargetImage, float progress, float reflection, float perspective, float depth) {
        vec2 p = samplerCoord(inputImage);

        vec2 pfr = vec2(-1.0), pto = vec2(-1.0);
        float middleSlit = 2.0 * abs(p.x-0.5) - progress;
        if (middleSlit > 0.0) {
            pfr = p + (p.x > 0.5 ? -1.0 : 1.0) * vec2(0.5*progress, 0.0);
            float d = 1.0/(1.0+perspective*progress*(1.0-middleSlit));
            pfr.y -= d/2.;
            pfr.y *= d;
            pfr.y += d/2.;
        }
        float size = mix(1.0, depth, 1.0-progress);

        p = samplerCoord(inputTargetImage);

        pto = (p + vec2(-0.5, -0.5)) * vec2(size, size) + vec2(0.5, 0.5);

        if (inBounds(pfr)) {
            return sample(inputImage, pfr);
        }
        else if (inBounds(pto)) {
            vec4 color = sample(inputTargetImage, pto);
            return color;
        }
        else {
            vec4 backgroundColor = bgColor(p, pto, reflection, inputTargetImage, progress);
            return backgroundColor;
        }
    }

    """
    
    private lazy var waveKernel: CIKernel? = {
        return CIKernel(source: sourceCode)
    }()
    
    @objc public var inputImage: CIImage?
    
    @objc public var inputTargetImage: CIImage?
    
    @objc public var inputTime: NSNumber = 1.0
    
    @objc public var reflection: NSNumber = 0.4
    
    @objc public var perspective: NSNumber = 0.4
    
    @objc public var depth: NSNumber = 3.0
    
    public override var outputImage: CIImage? {
        guard let kernel = waveKernel else { return nil }
        guard let inputImage = self.inputImage else { return nil }
        guard let inputTargetImage = self.inputTargetImage else { return nil }
        var finalFrame: CIImage = inputImage
        let aspectLength = max(inputImage.extent.size.width, inputImage.extent.size.height, inputTargetImage.extent.size.width, inputTargetImage.extent.size.height)
        let outputImageExtent = CGRect(origin: .zero, size: CGSize(width: aspectLength, height: aspectLength))
        finalFrame = kernel.apply(extent: outputImageExtent, roiCallback: { (index, destRect) -> CGRect in
            return destRect
        }, arguments: [finalFrame, inputTargetImage, inputTime.floatValue, reflection.floatValue, perspective.floatValue, depth.floatValue]) ?? finalFrame
        return finalFrame.cropped(to: outputImageExtent)
    }
    
}
