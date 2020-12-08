//
//  VCWaveform.swift
//  VideoClap
//
//  Created by laimincong on 2020/12/8.
//

import AVFoundation
import Accelerate

class VCWaveform: NSObject {
    
    let audioFileURL: URL
    
    init(url: URL) {
        audioFileURL = url
        super.init()
    }
    
    func points() throws -> [CGFloat] {
        let file = try AVAudioFile(forReading: audioFileURL)
        if let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: UInt32(file.length)) {
            if file.processingFormat.channelCount == .zero {
                throw NSError(domain: "", code: 2, userInfo: nil)
            }
            try file.read(into: buffer)
            let buffer = buffer
            let firstChannelData = buffer.floatChannelData?[0]
//            let secondChannelData = buffer.floatChannelData?[1]
            let sampleRate = file.processingFormat.sampleRate
            let sampleCount = buffer.frameLength
            
            if let firstChannelData = firstChannelData {
                vDSP_vabs(firstChannelData, 1, firstChannelData, 1, vDSP_Length(sampleCount))
                let samplesPerPixel = Int(sampleRate / 10.0)
                let filter = [Float](repeating: 1.0 / Float(samplesPerPixel),
                                     count: Int(samplesPerPixel))
                let downSampledLength = Int(Int(sampleCount) / samplesPerPixel)
                var downSampledData = [Float](repeating:0.0,
                                              count:downSampledLength)
                vDSP_desamp(firstChannelData,
                            vDSP_Stride(samplesPerPixel),
                            filter, &downSampledData,
                            vDSP_Length(downSampledLength),
                            vDSP_Length(samplesPerPixel))
                return downSampledData.map{CGFloat($0)}
            } else {
                throw NSError(domain: "", code: 1, userInfo: nil)
            }
            
        } else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
    }
    
    func waveformImage(height: CGFloat = 80.0, color: UIColor = .orange, offset: CGFloat = 2.5) throws -> UIImage? {
        let drawPoints = try points()
        let renderer = VCGraphicsRenderer()
        renderer.scale = UIScreen.main.scale
        let centerY = height / 2
        let halfHeight: CGFloat = height / 2.0
        renderer.rendererRect.size = CGSize(width: offset * CGFloat(drawPoints.count) + offset, height: height)
        return renderer.image { (context) in
            let aPath = UIBezierPath()
            aPath.move(to: CGPoint(x:0.0 , y: centerY))
            for point in drawPoints {
                aPath.addLine(to: CGPoint(x: aPath.currentPoint.x + offset, y: centerY - point * halfHeight))
            }
            aPath.addLine(to: CGPoint(x:aPath.currentPoint.x + offset , y: centerY ))
            for point in drawPoints.reversed() {
                aPath.addLine(to: CGPoint(x: aPath.currentPoint.x - offset, y: centerY + point * halfHeight))
            }
            aPath.move(to: CGPoint(x:0.0 , y: centerY))
            aPath.close()
            color.set()
            aPath.stroke()
            aPath.fill()
        }
    }
    
}
