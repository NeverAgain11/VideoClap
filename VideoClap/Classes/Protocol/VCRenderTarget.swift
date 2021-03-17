//
//  VCRenderTarget.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/16.
//

import AVFoundation

public protocol VCRenderTarget: NSObject {
    func draw(compositionTime: CMTime, images: [String : CIImage], blackImage: CIImage, renderSize: CGSize, renderScale: CGFloat) -> CIImage?
}
