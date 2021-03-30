//
//  AudioComponentDescription.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/23.
//

import AVFoundation

extension AudioComponentDescription {
    
    public init(componentType: OSType, componentSubType: OSType) {
        self.init(componentType: componentType,
                  componentSubType: componentSubType,
                  componentManufacturer: kAudioUnitManufacturer_Apple,
                  componentFlags: 0,
                  componentFlagsMask: 0)
    }
    
}
