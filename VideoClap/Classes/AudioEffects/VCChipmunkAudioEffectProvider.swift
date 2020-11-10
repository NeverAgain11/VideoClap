//
//  VCChipmunkAudioEffectProvider.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/10.
//

import AVFoundation

@available(iOS 11.0, *)
open class VCChipmunkAudioEffectProvider: VCBaseAudioEffectProvider {
    
    lazy var pitch: AVAudioUnitTimePitch = {
        let pitch = AVAudioUnitTimePitch()
        pitch.pitch = 1233
        pitch.rate = 1
        pitch.overlap = 8
        return pitch
    }()
    
    lazy var delay: AVAudioUnitDelay = {
        let delay = AVAudioUnitDelay()
        delay.delayTime = 0.02
        delay.wetDryMix = 53.8
        delay.feedback = 41.69
        return delay
    }()
    
    public override func supplyAudioUnits() -> [AVAudioUnit] {
        return [pitch, delay]
    }
    
}
