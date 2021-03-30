//
//  SCTRun.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/9.
//

import Foundation
import CoreText

open class SCTRun: NSObject {
    
    public let run: CTRun
    public let line: SCTLine
    public let frame: SCTFrame
    
    open override var description: String {
        return "\(run)"
    }
    
    open override var debugDescription: String {
        return "\(run)"
    }
    
    public var glyphCount: CFIndex {
        return CTRunGetGlyphCount(run)
    }
    
    public var attributes: NSDictionary {
        return CTRunGetAttributes(run)
    }
    
    public var status: CTRunStatus {
        return CTRunGetStatus(run)
    }
    
    public var glyphsGroup: [CGGlyph] {
        return [CGGlyph](unsafeUninitializedCapacity: glyphCount) { (bufferPointer, count) in
            if let address = bufferPointer.baseAddress {
                CTRunGetGlyphs(run, CFRange(), address)
                count = glyphCount
            }
        }
    }
    
    public var glyphsPtr: UnsafePointer<CGGlyph>? {
        CTRunGetGlyphsPtr(run)
    }
    
    public var stringRange: CFRange {
        return CTRunGetStringRange(run)
    }
    
    public var font: UIFont? {
        return attributes[kCTFontAttributeName] as? UIFont
    }
    
    public var foregroundColor: UIFont? {
        return attributes[kCTForegroundColorAttributeName] as? UIFont
    }
    
    public var glyphPositions: [CGPoint] {
        return [CGPoint](unsafeUninitializedCapacity: glyphCount) { (bufferPointer, count) in
            if let address = bufferPointer.baseAddress {
                CTRunGetPositions(run, CFRange(), address)
                count = glyphCount
            }
        }
    }
    
    public init(frame: SCTFrame, line: SCTLine, run: CTRun) {
        self.frame = frame
        self.line = line
        self.run = run
        super.init()
    }
    
    public func getGlyphs(range: CFRange) -> [CGGlyph] {
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
