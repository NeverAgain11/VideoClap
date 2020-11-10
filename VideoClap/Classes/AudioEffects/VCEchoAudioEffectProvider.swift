//
//  VCEchoAudioEffectProvider.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/9.
//

import AVFoundation

@available(iOS 11.0, *)
open class VCEchoAudioEffectProvider: VCBaseAudioEffectProvider {
    
    lazy var distortion: AVAudioUnitDistortion = {
        let distortion = AVAudioUnitDistortion()
        distortion.loadFactoryPreset(.multiEcho2)
        distortion.preGain = -6
        distortion.wetDryMix = 50
        return distortion
    }()
    
    public override func supplyAudioUnits() -> [AVAudioUnit] {
        return [distortion]
    }
    
}
