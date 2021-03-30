//
//  VCRequestItem.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

public class VCRequestItem {
    public var sourceFrameDic: [String : CIImage] = [:]
    
    public var instruction: VCVideoInstruction = .init()
}
