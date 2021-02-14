//
//  VCAudioUnitParameter.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/23.
//

import AVFoundation

public struct VCAudioUnitParameter: CustomStringConvertible {
    public let id: Int
    public let name: String?
    public let minValue: Float
    public let maxValue: Float
    public let defaultValue: Float
    public let unit: AudioUnitParameterUnit
    
    init(_ info: AudioUnitParameterInfo, id: UInt32) {
        self.id = Int(id)
        if let cfName = info.cfNameString?.takeUnretainedValue() {
            name = String(cfName)
        } else {
            name = nil 
        }
        minValue = Float(info.minValue)
        maxValue = Float(info.maxValue)
        defaultValue = Float(info.defaultValue)
        unit = info.unit
    }
    
    public var description: String {
        "id: \(id):  \(name) [\(minValue)..\(maxValue)] \(unit.rawValue)"
    }
}
