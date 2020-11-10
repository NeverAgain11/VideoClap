//
//  VCCaveAudioEffectProvider.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/10.
//

import AVFoundation

@available(iOS 11.0, *)
open class VCCaveAudioEffectProvider: VCBaseAudioEffectProvider {
    
    lazy var reverb: AVAudioUnitReverb = {
        let reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(.largeHall2)
        reverb.wetDryMix = 35
        return reverb
    }()
    
    public override func supplyAudioUnits() -> [AVAudioUnit] {
        return [reverb]
    }
    
}
