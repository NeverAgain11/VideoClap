//
//  VCEvilAudioEffectProvider.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/10.
//

import AVFoundation

@available(iOS 11.0, *)
open class VCEvilAudioEffectProvider: VCBaseAudioEffectProvider {
    
    lazy var pitch: AVAudioUnitTimePitch = {
        let pitch = AVAudioUnitTimePitch()
        pitch.pitch = -520.13
        pitch.rate = 1
        pitch.overlap = 8
        return pitch
    }()
    
    lazy var distortion: AVAudioUnitDistortion = {
        let distortion = AVAudioUnitDistortion()
        distortion.preGain = 4
        distortion.wetDryMix = 30
        return distortion
    }()
    
    lazy var delay: AVAudioUnitDelay = {
        let delay = AVAudioUnitDelay()
        delay.delayTime = 0.04
        delay.wetDryMix = 65.13
        delay.feedback = 55.34
        return delay
    }()
    
    public override func supplyAudioUnits() -> [AVAudioUnit] {
        return [pitch, distortion, delay]
    }
    
}
