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
    
    public var lottieTracks: [VCLottieTrackDescription] {
        return imageTracks.filter({ $0 is VCLottieTrackDescription }) as! [VCLottieTrackDescription]
    }
    
    public var laminationTracks: [VCLaminationTrackDescription] {
        return imageTracks.filter({ $0 is VCLaminationTrackDescription }) as! [VCLaminationTrackDescription]
    }
    
    public var textTracks: [VCTextTrackDescription] {
        return imageTracks.filter({ $0 is VCTextTrackDescription }) as! [VCTextTrackDescription]
    }
    
    internal func otherTracks() -> [VCTrackDescriptionProtocol] {
        var tracks: [VCTrackDescriptionProtocol] = []
        tracks.append(contentsOf: imageTracks)
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
        return copyObj
    }
    
}
