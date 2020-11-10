//
//  VCChildrenToAdultAudioEffectProvider.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/3.
//

import AVFoundation

@available(iOS 11.0, *)
open class VCChildrenToAdultAudioEffectProvider: VCBaseAudioEffectProvider {
    
    lazy var pitch: AVAudioUnitTimePitch = {
        let pitch = AVAudioUnitTimePitch()
        pitch.pitch = -440.9243
        pitch.rate = 1
        pitch.overlap = 8
        return pitch
    }()
    
    public override func supplyAudioUnits() -> [AVAudioUnit] {
        return [pitch]
    }
    
}
