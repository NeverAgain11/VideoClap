//
//  SCTRun.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/9.
//

import Foundation
import CoreText

class SCTRun: NSObject {
    
    let run: CTRun
    let line: SCTLine
    let frame: SCTFrame
    
    override var description: String {
        return "\(run)"
    }
    
    override var debugDescription: String {
        return "\(run)"
    }
    
    var glyphCount: CFIndex {
        return CTRunGetGlyphCount(run)
    }
    
    var attributes: NSDictionary {
        return CTRunGetAttributes(run)
    }
    
    var status: CTRunStatus {
        return CTRunGetStatus(run)
    }
    
    var glyphsGroup: [CGGlyph] {
        return [CGGlyph](unsafeUninitializedCapacity: glyphCount) { (bufferPointer, count) in
            if let address = bufferPointer.baseAddress {
                CTRunGetGlyphs(run, CFRange(), address)
                count = glyphCount
            }
        }
    }
    
    var glyphsPtr: UnsafePointer<CGGlyph>? {
        CTRunGetGlyphsPtr(run)
    }
    
    var stringRange: CFRange {
        return CTRunGetStringRange(run)
    }
    
    var font: UIFont? {
        return attributes[kCTFontAttributeName] as? UIFont
    }
    
    var foregroundColor: UIFont? {
        return attributes[kCTForegroundColorAttributeName] as? UIFont
    }
    
    var glyphPositions: [CGPoint] {
        return [CGPoint](unsafeUninitializedCapacity: glyphCount) { (bufferPointer, count) in
            if let address = bufferPointer.baseAddress {
                CTRunGetPositions(run, CFRange(), address)
                count = glyphCount
            }
        }
    }
    
    init(frame: SCTFrame, line: SCTLine, run: CTRun) {
        self.frame = frame
        self.line = line
        self.run = run
        super.init()
    }
    
    func getGlyphs(range: CFRange) -> [CGGlyph] {
        var group: [CGGlyph] = .init(repeating: CGGlyph(), count: range.length)
        CTRunGetGlyphs(run, range, &group)
        return group
    }
    
    public func boundingRects(orientation: CTFontOrientation = .default) -> [CGRect] {
        if let font = self.font {
            return [CGRect](unsafeUninitializedCapacity: glyphCount) { (bufferPointer, count) in
                if let ptr = glyphsPtr {
                    CTFontGetBoundingRectsForGlyphs(font, orientation, ptr, bufferPointer.baseAddress, glyphCount)
                    count = glyphCount
                }
            }
        } else {
            return []
        }
    }
    
}
