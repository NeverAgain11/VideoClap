//
//  VCTextEffectProviderProtocol.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/14.
//

import Foundation

public protocol VCTextEffectProviderProtocol: NSObject {
    
    func effectImage(context: VCTextEffectRenderContext) -> CIImage?
    
}
