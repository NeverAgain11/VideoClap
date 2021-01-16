//
//  CIContext.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/14.
//

import Foundation

internal extension CIContext {
    
    static let share: CIContext = {
        if let gpu = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: gpu)
        }
        if let eaglContext = EAGLContext(api: .openGLES3) ?? EAGLContext(api: .openGLES2) {
            return CIContext(eaglContext: eaglContext)
        }
        return CIContext()
    }()
    
}
