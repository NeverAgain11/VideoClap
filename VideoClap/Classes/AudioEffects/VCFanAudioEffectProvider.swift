//
//  VCFanAudioEffectProvider.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/3.
//

import AVFoundation

@available(iOS 11.0, *)
open class VCFanAudioEffectProvider: VCBaseAudioEffectProvider {
    
    lazy var pitch: AVAudioUnitTimePitch = {
        let pitch = AVAudioUnitTimePitch()
        pitch.pitch = 29.04
        pitch.rate = 1
        pitch.overlap = 8
        return pitch
    }()
    
    lazy var delay: AVAudioUnitDelay = {
        let delay = AVAudioUnitDelay()
        delay.delayTime = 0.01
        delay.feedback = 87.02
        delay.wetDryMix = 65.46
        return delay
    }()
    
    lazy var reverb: AVAudioUnitReverb = {
        let reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(.largeHall)
        reverb.wetDryMix = 50
        return reverb
    }()
    
    public override func supplyAudioUnits() -> [AVAudioUnit] {
        return [pitch, delay, reverb]
    }
    
}
