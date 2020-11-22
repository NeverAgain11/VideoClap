//
//  VCVideoDescription.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/22.
//

import AVFoundation

open class VCVideoDescription: NSObject, NSCopying, NSMutableCopying {
    
    public var renderSize: CGSize = .zero
    
    public var renderScale: Float = 1.0
    
    public var fps: Double = 24.0
    
    public var waterMarkRect: VCRect?
    
    public var waterMarkImageURL: URL?
    
    public var imageTracks: [VCImageTrackDescription] = []
    
    public var videoTracks: [VCVideoTrackDescription] = []
    
    public var audioTracks: [VCAudioTrackDescription] = []
    
    public var lottieTracks: [VCLottieTrackDescription] = []
    
    public var laminationTracks: [VCLaminationTrackDescription] = []
    
    
    public var transitions: [VCTransitionProtocol] = []
    
    public var trajectories: [VCTrajectoryProtocol] = []
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copyObj = VCVideoDescription()
        copyObj.renderSize       = self.renderSize
        copyObj.renderScale      = self.renderScale
        copyObj.fps              = self.fps
        copyObj.imageTracks      = imageTracks.map({ $0.mutableCopy() as! VCImageTrackDescription })
        copyObj.videoTracks      = videoTracks.map({ $0.mutableCopy() as! VCVideoTrackDescription })
        copyObj.audioTracks      = audioTracks.map({ $0.mutableCopy() as! VCAudioTrackDescription })
        copyObj.lottieTracks     = lottieTracks.map({ $0.mutableCopy() as! VCLottieTrackDescription })
        copyObj.laminationTracks = laminationTracks.map({ $0.mutableCopy() as! VCLaminationTrackDescription })
        return copyObj
    }
    
}
