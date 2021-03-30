//
//  VCLutFilter.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/29.
//

import Foundation
import CoreImage

open class VCLutFilter: CIFilter {
    
    public static let share = VCLutFilter()
    
    private static let sourceCode = """
    kernel vec4 YasicLUT(sampler inputImage, sampler inputLUT, float intensity) {
        vec4 textureColor = sample(inputImage, samplerCoord(inputImage));
        textureColor = clamp(textureColor, vec4(0.0), vec4(1.0));
        float blueColor = textureColor.b * 63.0;

        highp vec2 quad1;
        quad1.y = floor(floor(blueColor) / 8.0);
        quad1.x = floor(blueColor) - (quad1.y * 8.0);
        highp vec2 quad2;
        quad2.y = floor(ceil(blueColor) / 8.0);
        quad2.x = ceil(blueColor) - (quad2.y * 8.0);

        highp vec2 texPos1;
        texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
        texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

        highp vec2 texPos2;
        texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
        texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

        vec4 newColor1 = sample(inputLUT, texPos1);
        vec4 newColor2 = sample(inputLUT, texPos2);
        vec4 newColor = mix(newColor1, newColor2, fract(blueColor));

        return mix(textureColor, vec4(newColor.rgb, textureColor.a), intensity);
    }
    """
    
    private static let kernel: CIKernel? = {
        return CIKernel(source: sourceCode)
    }()
    
    public var lookupImage: CIImage?
    
    @objc public var inputImage: CIImage?
    
    @objc public var inputIntensity: NSNumber = 1.0
    
    lazy var context: CIContext = {
        var options: [CIContextOption : Any] = [:]
        options[.workingColorSpace] = CGColorSpace(name: CGColorSpace.sRGB)
        options[.outputColorSpace] = CGColorSpaceCreateDeviceRGB()
        let context = CIContext(options: options)
        return context
    }()
    
    public override var outputImage: CIImage? {
        guard let kernel = VCLutFilter.kernel else { return nil }
        guard let inputImage = self.inputImage else { return nil }
        guard let lookupImage = self.lookupImage else { return nil }
        var finalFrame: CIImage = inputImage
        
        finalFrame = kernel.apply(extent: finalFrame.extent, roiCallback: { (index, destRect) -> CGRect in
            return index == 0 ? destRect : lookupImage.extent
        }, arguments: [finalFrame, lookupImage, inputIntensity.floatValue]) ?? finalFrame
        if #available(iOS 10.0, *) {
            finalFrame = finalFrame.matchedFromWorkingSpace(to: CGColorSpaceCreateDeviceRGB()) ?? finalFrame
        } else {
            let origin = finalFrame.extent.origin
            if let cgImage = context.createCGImage(finalFrame, from: finalFrame.extent) {
                finalFrame = CIImage(cgImage: cgImage)
                finalFrame = finalFrame.transformed(by: .init(translationX: origin.x, y: origin.y))
            }
        }
        return finalFrame
    }
    
}
