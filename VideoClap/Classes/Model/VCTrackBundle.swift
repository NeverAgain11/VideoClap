//
//  VCTrackBundle.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/4.
//

import Foundation

open class VCTrackBundle: NSObject, NSCopying, NSMutableCopying {
    
    public var imageTracks: [VCImageTrackDescription] = []
    
    public var videoTracks: [VCVideoTrackDescription] = []
    
    public var audioTracks: [VCAudioTrackDescription] = []
    
    public var lottieTracks: [VCLottieTrackDescription] = []
    
    public var laminationTracks: [VCLaminationTrackDescription] = []
    
    internal func allTracks() -> [VCTrackDescriptionProtocol] {
        var tracks: [VCTrackDescriptionProtocol] = []
        tracks.append(contentsOf: imageTracks)
        tracks.append(contentsOf: videoTracks)
        tracks.append(contentsOf: lottieTracks)
        tracks.append(contentsOf: laminationTracks)
        tracks.append(contentsOf: audioTracks)
        return tracks
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCTrackBundle()
        copyObj.imageTracks      = imageTracks.map({ $0.mutableCopy() as! VCImageTrackDescription })
        copyObj.videoTracks      = videoTracks.map({ $0.mutableCopy() as! VCVideoTrackDescription })
        copyObj.audioTracks      = audioTracks.map({ $0.mutableCopy() as! VCAudioTrackDescription })
        copyObj.lottieTracks     = lottieTracks.map({ $0.mutableCopy() as! VCLottieTrackDescription })
        copyObj.laminationTracks = laminationTracks.map({ $0.mutableCopy() as! VCLaminationTrackDescription })
        return copyObj
    }
    
}
