//
//  VCRenderTarget.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/16.
//

import Foundation

public protocol VCRenderTarget: NSObject {
    func contextChanged()
    func draw(images: [String:CIImage], blackImage: CIImage) -> CIImage?
}
