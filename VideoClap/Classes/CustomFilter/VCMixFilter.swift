//
//  VCMixFilter.swift
//  VideoClap
//
//  Created by laimincong on 2020/12/2.
//

import Foundation
import CoreImage

open class VCMixFilter: CIFilter {
    
    private static let sourceCode = """
    kernel vec4 main(sampler inputImage, sampler inputTargetImage, float m) {
        vec4 color0 = sample(inputImage, samplerCoord(inputImage));
        vec4 color1 = sample(inputTargetImage, samplerCoord(inputTargetImage));
        return vec4(mix(color0.rgb, color1.rgb, m), 1.0);
    }
    """
    
    private static let kernel: CIKernel? = {
        return CIKernel(source: sourceCode)
    }()
    
    @objc public var inputImage: CIImage?
    
    @objc public var inputTargetImage: CIImage?
    
    @objc public var mix: NSNumber = 1.0
    
    public override var outputImage: CIImage? {
        guard let kernel = VCMixFilter.kernel else { return nil }
        guard let inputImage = self.inputImage else { return nil }
        guard let inputTargetImage = self.inputTargetImage else { return nil }
        var finalFrame: CIImage = inputImage
        
        finalFrame = kernel.apply(extent: finalFrame.extent, roiCallback: { (index, destRect) -> CGRect in
            return index == 0 ? destRect : inputTargetImage.extent
        }, arguments: [finalFrame, inputTargetImage, mix.floatValue]) ?? finalFrame
        
        return finalFrame
    }
    
}
