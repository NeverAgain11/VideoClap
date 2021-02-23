//
//  MetalDevice.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/22.
//

import Foundation
import Metal

public class MetalDevice: NSObject {
    
    public static let `default` = MTLCreateSystemDefaultDevice()
    
    public internal(set) lazy var commandQueue: MTLCommandQueue? = {
        return MetalDevice.default?.makeCommandQueue()
    }()
    
    public internal(set) lazy var lib: MTLLibrary? = {
        if let url = VCHelper.defaultMetalLibURL() {
            do {
                let lib = try MetalDevice.default?.makeLibrary(filepath: url.path)
                return lib
            } catch let error {
                log.error(error)
            }
        }
        return nil
    }()
    
}
