//
//  VCBotAudioEffectProvider.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/9.
//

import AVFoundation

@available(iOS 11.0, *)
open class VCBotAudioEffectProvider: VCBaseAudioEffectProvider {
    
    lazy var pitch: AVAudioUnitTimePitch = {
        let pitch = AVAudioUnitTimePitch()
        pitch.pitch = -340.59
        pitch.rate = 1
        pitch.overlap = 8
        return pitch
    }()
    
    lazy var distortion: AVAudioUnitDistortion = {
        let distortion = AVAudioUnitDistortion()
        distortion.preGain = 0
        distortion.wetDryMix = 50
        return distortion
    }()
    
    lazy var delay: AVAudioUnitDelay = {
        let delay = AVAudioUnitDelay()
        delay.delayTime = 0.01
        delay.wetDryMix = 58.53
        delay.feedback = 88.12
        return delay
    }()
    
    public override func supplyAudioUnits() -> [AVAudioUnit] {
        return [pitch, distortion, delay]
    }
    
}
