//
//  SCTLine.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/9.
//

import Foundation
import CoreText

public struct SCTTypographicBounds {
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    var width: CGFloat = 0
    
    var height: CGFloat {
        return ascent + descent + leading
    }
}

public struct SCTOffsetResult {
    var primaryOffset: CGFloat = 0
    var secondaryOffset: CGFloat = 0
}

open class SCTLine: NSObject {
    
    public let line: CTLine
    public let sctFrame: SCTFrame
    
    open override var description: String {
        return "\(line)"
    }
    
    open override var debugDescription: String {
        return "\(line)"
    }
    
    public var stringRange: CFRange {
        return CTLineGetStringRange(line)
    }
    
    public var typographicBounds: SCTTypographicBounds {
        var bounds = SCTTypographicBounds()
        bounds.width = CGFloat(CTLineGetTypographicBounds(line, &bounds.ascent, &bounds.descent, &bounds.leading))
        return bounds
    }

    public var charOffsets: [SCTOffsetResult] {
        return (0..<glyphRuns.count).map({ self.getOffsetForStringIndex(charIndex: $0) })
    }
    
    public var glyphRuns: [SCTRun] {
        let runs = CTLineGetGlyphRuns(line) as? [CTRun] ?? []
        return runs.map({ SCTRun(frame: sctFrame, line: self, run: $0) })
    }
    
    public init(frame: SCTFrame, line: CTLine) {
        self.line = line
        self.sctFrame = frame
        super.init()
    }
    
    public func getOffsetForStringIndex(charIndex: CFIndex) -> SCTOffsetResult {
        var result = SCTOffsetResult()
        result.primaryOffset = CTLineGetOffsetForStringIndex(line, charIndex, &result.secondaryOffset)
        return result
    }
    
}
