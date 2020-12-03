//
//  VCRequestItem.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

public struct VCRequestItem {
    var sourceFrameDic: [String : CIImage] = [:]
    
    var instruction: VCVideoInstruction = .init()
}
