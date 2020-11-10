//
//  VCSlowAudioEffectProvider.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/3.
//

import AVFoundation

@available(iOS 11.0, *)
open class VCSlowAudioEffectProvider: VCBaseAudioEffectProvider {
    
    lazy var rate: AVAudioUnitVarispeed = {
        let rate = AVAudioUnitVarispeed()
        rate.rate = 0.2
        return rate
    }()
    
    public override func supplyAudioUnits() -> [AVAudioUnit] {
        return [rate]
    }
    
}
