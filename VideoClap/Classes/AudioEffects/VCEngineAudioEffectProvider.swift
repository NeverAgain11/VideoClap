//
//  VCEngineAudioEffectProvider.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/10.
//

import AVFoundation

@available(iOS 11.0, *)
open class VCEngineAudioEffectProvider: VCBaseAudioEffectProvider {
    
    lazy var pitch: AVAudioUnitTimePitch = {
        let pitch = AVAudioUnitTimePitch()
        pitch.pitch = -435.64
        pitch.rate = 1
        pitch.overlap = 8
        return pitch
    }()
    
    lazy var distortion: AVAudioUnitDistortion = {
        let distortion = AVAudioUnitDistortion()
        distortion.preGain = -6
        distortion.wetDryMix = 30
        return distortion
    }()
    
    public override func supplyAudioUnits() -> [AVAudioUnit] {
        return [pitch, distortion]
    }
    
}
