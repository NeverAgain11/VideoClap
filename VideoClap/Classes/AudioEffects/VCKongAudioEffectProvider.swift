//
//  VCKongAudioEffectProvider.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/10.
//

import AVFoundation

@available(iOS 11.0, *)
open class VCKongAudioEffectProvider: VCBaseAudioEffectProvider {
    
    lazy var pitch: AVAudioUnitTimePitch = {
        let pitch = AVAudioUnitTimePitch()
        pitch.pitch = -1914.1915
        pitch.rate = 1
        pitch.overlap = 8
        return pitch
    }()
    
    public override func supplyAudioUnits() -> [AVAudioUnit] {
        return [pitch]
    }
    
}
