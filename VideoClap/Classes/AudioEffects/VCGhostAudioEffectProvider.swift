//
//  VCGhostAudioEffectProvider.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/3.
//

import AVFoundation

@available(iOS 11.0, *)
open class VCGhostAudioEffectProvider: VCBaseAudioEffectProvider {
    
    lazy var pitch: AVAudioUnitTimePitch = {
        let pitch = AVAudioUnitTimePitch()
        pitch.pitch = 662.71
        pitch.rate = 1
        pitch.overlap = 8
        return pitch
    }()
    
    lazy var distortion: AVAudioUnitDistortion = {
        let distortion = AVAudioUnitDistortion()
        distortion.preGain = -6
        distortion.wetDryMix = 30
        distortion.loadFactoryPreset(.multiEcho2)
        return distortion
    }()
    
    lazy var delay: AVAudioUnitDelay = {
        let delay = AVAudioUnitDelay()
        delay.delayTime = 0.02
        delay.feedback = 80.64
        delay.wetDryMix = 65.13
        return delay
    }()
    
    public override func supplyAudioUnits() -> [AVAudioUnit] {
        return [pitch, distortion, delay]
    }
    
}
