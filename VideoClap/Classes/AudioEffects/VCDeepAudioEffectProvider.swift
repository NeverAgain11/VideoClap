//
//  VCDeepAudioEffectProvider.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/10.
//

import AVFoundation

@available(iOS 11.0, *)
open class VCDeepAudioEffectProvider: VCBaseAudioEffectProvider {
    
    lazy var pitch: AVAudioUnitTimePitch = {
        let pitch = AVAudioUnitTimePitch()
        pitch.pitch = 0
        pitch.rate = 1
        pitch.overlap = 8
        return pitch
    }()
    
    lazy var reverb: AVAudioUnitReverb = {
        let reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(.smallRoom)
        reverb.wetDryMix = 64.58
        return reverb
    }()
    
    lazy var delay: AVAudioUnitDelay = {
        let delay = AVAudioUnitDelay()
        delay.delayTime = 0.04
        delay.wetDryMix = 65.13
        delay.feedback = 70.08
        return delay
    }()
    
    public override func supplyAudioUnits() -> [AVAudioUnit] {
        return [pitch, reverb, delay]
    }
    
}
