//
//  VCVideoProcessProtocol.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/8.
//

import AVFoundation

public protocol VCVideoProcessProtocol: NSObject {
    
    func handle(item: VCRequestItem, compositionTime: CMTime, blackImage: CIImage, finish: (CIImage?) -> Void)
    
}
