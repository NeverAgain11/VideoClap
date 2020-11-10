//
//  VCRobotAudioEffectProvider.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/10.
//

import AVFoundation

@available(iOS 11.0, *)
open class VCRobotAudioEffectProvider: VCBaseAudioEffectProvider {
    
    lazy var pitch: AVAudioUnitTimePitch = {
        let pitch = AVAudioUnitTimePitch()
        pitch.pitch = -240.26
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
        delay.wetDryMix = 65.46
        delay.feedback = 87.02
        return delay
    }()
    
    public override func supplyAudioUnits() -> [AVAudioUnit] {
        return [pitch, distortion, delay]
    }
    
}
