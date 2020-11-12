//
//  VCRequestCallbackHandlerProtocol.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/27.
//

import AVFoundation

public protocol VCRequestCallbackHandlerProtocol: VCVideoProcessProtocol, VCAudioProcessingTapProcessProtocol {
    
    var videoDescription: VCVideoDescriptionProtocol { get set }
    
    func contextChanged()
    
}
