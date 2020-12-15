//
//  Array.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/15.
//

import Foundation

extension Array where Element: VCTrackDescriptionProtocol {
    
    func dic() -> [String:Element] {
        return self.reduce([:]) { (result, imageTrack) -> [String : Element] in
            var mutable = result
            mutable[imageTrack.id] = imageTrack
            return mutable
        }
    }
    
}

extension Array where Element: VCScaleTrackDescriptionProtocol {
    
    func dic() -> [String:Element] {
        return self.reduce([:]) { (result, imageTrack) -> [String : Element] in
            var mutable = result
            mutable[imageTrack.id] = imageTrack
            return mutable
        }
    }
    
}
