//
//  VCMediaTrackDescriptionProtocol.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/22.
//

import AVFoundation

public protocol VCMediaTrackDescriptionProtocol: VCTrackDescriptionProtocol {
    
    var id: String { get set }
    
    var timeRange: CMTimeRange { get set }
    
    var mediaClipTimeRange: CMTimeRange { get set }
    
    var mediaURL: URL? { get set }
    
    var associationInfo: MediaTrackAssociationInfo { get set }
}

public class MediaTrackAssociationInfo: NSObject {
    
    internal var persistentTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    internal var compositionTrack: AVMutableCompositionTrack?
    internal var fixClipTimeRange: CMTimeRange = .zero
    
}

internal extension VCMediaTrackDescriptionProtocol {
    internal var persistentTrackID: CMPersistentTrackID {
        get { return associationInfo.persistentTrackID }
        set { associationInfo.persistentTrackID = newValue }
    }
    internal var compositionTrack: AVMutableCompositionTrack? {
        get { return associationInfo.compositionTrack }
        set { associationInfo.compositionTrack = newValue }
    }
    internal var fixClipTimeRange: CMTimeRange {
        get { return associationInfo.fixClipTimeRange }
        set { associationInfo.fixClipTimeRange = newValue }
    }
}
