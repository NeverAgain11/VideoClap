//
//  VCCrazyAudioEffectProvider.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/9.
//

import AVFoundation

@available(iOS 11.0, *)
open class VCCrazyAudioEffectProvider: VCBaseAudioEffectProvider {
    
    lazy var delay: AVAudioUnitDelay = {
        let delay = AVAudioUnitDelay()
        delay.delayTime = 0.004
        delay.wetDryMix = 56.88
        delay.feedback = 89.66
        return delay
    }()
    
    lazy var rate: AVAudioUnitVarispeed = {
        let rate = AVAudioUnitVarispeed()
        rate.rate = 1.1
        return rate
    }()
    
    lazy var reverb: AVAudioUnitReverb = {
        let reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(.smallRoom)
        reverb.wetDryMix = 50
        return reverb
    }()
    
    public override func supplyAudioUnits() -> [AVAudioUnit] {
        return [delay, rate, reverb]
    }
    
}
