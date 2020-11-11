//
//  VCTrack.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/24.
//

import AVFoundation

internal class VCTrack: VCTrackDescription {
    
    var persistentTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    
    init(description: VCTrackDescriptionProtocol, persistentTrackID: CMPersistentTrackID) {
        super.init(id: description.id, trackType: description.trackType, timeRange: description.timeRange)
        self.persistentTrackID           = persistentTrackID
        self.prefferdTransform           = description.prefferdTransform
        self.mediaURL                    = description.mediaURL
        self.mediaClipTimeRange          = description.mediaClipTimeRange
        self.imageClosure                = description.imageClosure
        self.audioVolumeRampDescriptions = description.audioVolumeRampDescriptions
    }
    
    override func mutableCopy(with zone: NSZone? = nil) -> Any {
        var copyObj = super.mutableCopy(with: zone) as! VCTrackDescriptionProtocol
        copyObj = VCTrack(description: copyObj, persistentTrackID: self.persistentTrackID)
        return copyObj
    }
    
}
