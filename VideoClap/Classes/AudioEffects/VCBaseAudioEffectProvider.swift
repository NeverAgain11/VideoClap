//
//  VCBaseAudioEffectProvider.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/9.
//

import AVFoundation
import Accelerate

@available(iOS 11.0, *)
open class VCBaseAudioEffectProvider: NSObject, VCAudioEffectProviderProtocol {
    
    let engine: AVAudioEngine = AVAudioEngine()
    
    public func supplyAudioUnits() -> [AVAudioUnit] {
        fatalError("supplyAudioUnits(:) has not been implemented")
    }
    
    public func handle(timeRange: CMTimeRange, inCount: CMItemCount, inFlag: MTAudioProcessingTapFlags, outBuffer: UnsafeMutablePointer<AudioBufferList>, outCount: UnsafeMutablePointer<CMItemCount>, outFlag: UnsafeMutablePointer<MTAudioProcessingTapFlags>, pcmFormat: AVAudioFormat) {
        
//        let bufferList = UnsafeMutableAudioBufferListPointer(outBuffer)
//        for bufferIndex in 0..<bufferList.count {
//            let audioBuffer = bufferList[bufferIndex]
//            let channelData = UnsafeMutableBufferPointer<Float>(audioBuffer).map({ $0 })
//        }
        
        let audioUnits = supplyAudioUnits()
        guard audioUnits.isEmpty == false else {
            return
        }
        do {
            let engine: AVAudioEngine = AVAudioEngine()
//            let bufferPointer = UnsafeMutableAudioBufferListPointer(buffer)
//            for item in bufferPointer {
//                let data = item.mData
//                let size = item.mDataByteSize
//                let numChannels = item.mNumberChannels
//                print(size, numChannels)
//            }
            
            if let pcmbuffer = convertRawBufferToPCMBuffer(rawBuffer: outBuffer, format: pcmFormat, to: AVAudioFramePosition(inCount)) {
                
                let player = AVAudioPlayerNode()
                
                var nodeGroup: [AVAudioNode] = []
                nodeGroup.append(player)
                nodeGroup.append(contentsOf: audioUnits)
                for node in nodeGroup {
                    engine.attach(node)
                }
                nodeGroup.append(engine.mainMixerNode)
                for index in 0..<nodeGroup.count - 1 {
                    engine.connect(nodeGroup[index], to: nodeGroup[index + 1], format: pcmFormat)
                }
                
                player.scheduleBuffer(pcmbuffer, completionHandler: nil)
                
                try engine.enableManualRenderingMode(.offline, format: pcmFormat, maximumFrameCount: AVAudioFrameCount(AVAudioFramePosition(inCount)))
                engine.prepare()
                try engine.start()
                player.play()
                try engine.renderOffline(engine.manualRenderingMaximumFrameCount, to: pcmbuffer)
                
                fillBuffer(outBuffer, use: pcmbuffer, inCount: inCount)
                engine.disableManualRenderingMode()
                engine.stop()
            }
        } catch let error {
            log.error(error)
        }
    }
    
    private func fillBuffer(_ outBuffer: UnsafeMutablePointer<AudioBufferList>, use pcmBuffer: AVAudioPCMBuffer, inCount: CMItemCount) {
        let srcPtr = UnsafeMutableAudioBufferListPointer(pcmBuffer.mutableAudioBufferList)
        let dstPtr = UnsafeMutableAudioBufferListPointer(outBuffer)
        let sampleSize = pcmBuffer.format.streamDescription.pointee.mBytesPerFrame
        for (src, dst) in zip(srcPtr, dstPtr) {
            memcpy(dst.mData, src.mData?.advanced(by: Int(0) * Int(sampleSize)), Int(inCount) * Int(sampleSize))
        }
    }
    
    private func convertRawBufferToPCMBuffer(rawBuffer: UnsafeMutablePointer<AudioBufferList>, format: AVAudioFormat, from startFrame: AVAudioFramePosition = 0, to endFrame: AVAudioFramePosition) -> AVAudioPCMBuffer? {
        let framesToCopy = AVAudioFrameCount(endFrame - startFrame)
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: framesToCopy) else { return nil }

        let sampleSize = format.streamDescription.pointee.mBytesPerFrame

        let srcPtr = UnsafeMutableAudioBufferListPointer(rawBuffer)
        let dstPtr = UnsafeMutableAudioBufferListPointer(pcmBuffer.mutableAudioBufferList)
        for (src, dst) in zip(srcPtr, dstPtr) {
            memcpy(dst.mData, src.mData?.advanced(by: Int(startFrame) * Int(sampleSize)), Int(framesToCopy) * Int(sampleSize))
        }

        pcmBuffer.frameLength = framesToCopy
        return pcmBuffer
    }
    
    func changeVolume(for bufferList: UnsafeMutablePointer<AudioBufferList>, volume: Float) {
        let bufferList = UnsafeMutableAudioBufferListPointer(bufferList)
        for bufferIndex in 0..<bufferList.count {
            let audioBuffer = bufferList[bufferIndex]
            if let rawBuffer = audioBuffer.mData {
                let floatRawPointer = rawBuffer.assumingMemoryBound(to: Float.self)
                let frameCount = UInt(audioBuffer.mDataByteSize) / UInt(MemoryLayout<Float>.size)
                var volume = volume
                vDSP_vsmul(floatRawPointer, 1, &volume, floatRawPointer, 1, frameCount)
            }
        }
    }
    
}
