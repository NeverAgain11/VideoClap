//
//  SCTFrame.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/9.
//

import Foundation
import CoreText

open class SCTFrame: NSObject {
    
    public let attrString: NSAttributedString
    public let ctFrame: CTFrame
    public let framesetter: SCTFramesetter
    
    open override var description: String {
        return "\(ctFrame)"
    }
    
    open override var debugDescription: String {
        return "\(ctFrame)"
    }
    
    var stringRange: CFRange {
        return CTFrameGetStringRange(ctFrame)
    }
    
    var visibleStringRange: CFRange {
        return CTFrameGetVisibleStringRange(ctFrame)
    }
    
    var path: CGPath {
        return CTFrameGetPath(ctFrame)
    }
    
    var frameAttributes: NSDictionary? {
        return CTFrameGetFrameAttributes(ctFrame)
    }
    
    var lines: [SCTLine] {
        let lines: [CTLine] = CTFrameGetLines(ctFrame) as? [CTLine] ?? []
        return lines.map({ SCTLine(frame: self, line: $0) })
    }
    
    var lineFrames: [CGRect] {
        var rects: [CGRect] = []
        for (index, line) in lines.enumerated() {
            let origin: CGPoint = self.getLineOrigin(location: index)
            let bounds = line.typographicBounds
            let lineWidth = bounds.width
            let lineHeight = bounds.height
            let rect = CGRect(origin: origin, size: CGSize(width: lineWidth, height: lineHeight))
            rects.append(rect)
        }
        return rects
    }
    
    init(framesetter: SCTFramesetter, ctFrame: CTFrame, attrString: NSAttributedString) {
        self.ctFrame = ctFrame
        self.framesetter = framesetter
        self.attrString = attrString
        super.init()
    }
    
    func draw() throws {
        guard let context = UIGraphicsGetCurrentContext() else { throw NSError(domain: "SwiftyCoreText", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey : "context nil"]) }
        CTFrameDraw(ctFrame, context)
    }
    
    func draw(in context: CGContext) {
        CTFrameDraw(ctFrame, context)
    }
    
    func getLineOrigin(location: CFIndex) -> CGPoint {
        var points: [CGPoint] = .init(repeating: CGPoint.zero, count: 1)
        CTFrameGetLineOrigins(ctFrame, CFRange(location: location, length: 1), &points)
        return points[0]
    }
    
    func lineOrigins() -> [CGPoint] {
        let lineCount = lines.count
        return [CGPoint](unsafeUninitializedCapacity: lineCount) { (bufferPointer, count) in
            if let ptr = bufferPointer.baseAddress {
                CTFrameGetLineOrigins(self.ctFrame, CFRange(), ptr)
                count = lineCount
            }
        }
    }
    
    func characterRects() -> [CGRect] {
        let origins = lineOrigins()
        var rects: [CGRect] = []
        for (line, origin) in zip(lines, origins) {
            for run in line.glyphRuns {
                for (index, glyphPosition) in run.glyphPositions.enumerated() {
                    var boundingRect = run.boundingRects()[index]
                    boundingRect.origin = boundingRect.origin.add(glyphPosition).add(origin)
                    rects.append(boundingRect)
                }
            }
        }
        return rects
    }
    
    func characters() -> [SCTCharacter] {
        let rects = characterRects()
        let characters = separateAttributeString(self.attrString)
        
        guard rects.count == characters.count else {
            return []
        }
        
        return zip(rects, characters).map { (frame, character) -> SCTCharacter in
            return SCTCharacter(character: character, frame: frame)
        }
    }
    
    func separateAttributeString(_ attributeString: NSAttributedString) -> [NSAttributedString] {
        var subCharacters: [NSAttributedString] = []
        for index in 0..<attributeString.length {
            let range = NSRange(location: index, length: 1)
            let subString = attributeString.attributedSubstring(from: range)
            subCharacters.append(subString)
        }
        return subCharacters
    }
    
}
