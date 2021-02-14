//
//  SCTLine.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/9.
//

import Foundation
import CoreText

struct SCTTypographicBounds {
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    var width: CGFloat = 0
    
    var height: CGFloat {
        return ascent + descent + leading
    }
}

struct SCTOffsetResult {
    var primaryOffset: CGFloat = 0
    var secondaryOffset: CGFloat = 0
}

class SCTLine: NSObject {
    
    let line: CTLine
    let sctFrame: SCTFrame
    
    override var description: String {
        return "\(line)"
    }
    
    override var debugDescription: String {
        return "\(line)"
    }
    
    var stringRange: CFRange {
        return CTLineGetStringRange(line)
    }
    
    var typographicBounds: SCTTypographicBounds {
        var bounds = SCTTypographicBounds()
        bounds.width = CGFloat(CTLineGetTypographicBounds(line, &bounds.ascent, &bounds.descent, &bounds.leading))
        return bounds
    }

    var charOffsets: [SCTOffsetResult] {
        return (0..<glyphRuns.count).map({ self.getOffsetForStringIndex(charIndex: $0) })
    }
    
    var glyphRuns: [SCTRun] {
        let runs = CTLineGetGlyphRuns(line) as? [CTRun] ?? []
        return runs.map({ SCTRun(frame: sctFrame, line: self, run: $0) })
    }
    
    init(frame: SCTFrame, line: CTLine) {
        self.line = line
        self.sctFrame = frame
        super.init()
    }
    
    func getOffsetForStringIndex(charIndex: CFIndex) -> SCTOffsetResult {
        var result = SCTOffsetResult()
        result.primaryOffset = CTLineGetOffsetForStringIndex(line, charIndex, &result.secondaryOffset)
        return result
    }
    
}
