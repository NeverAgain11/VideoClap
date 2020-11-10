//
//  VCFastAudioEffectProvider.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/3.
//

import AVFoundation

@available(iOS 11.0, *)
open class VCFastAudioEffectProvider: VCBaseAudioEffectProvider {
    
    lazy var rate: AVAudioUnitVarispeed = {
        let rate = AVAudioUnitVarispeed()
        rate.rate = 4.0
        return rate
    }()
    
    public override func supplyAudioUnits() -> [AVAudioUnit] {
        return [rate]
    }
    
}
