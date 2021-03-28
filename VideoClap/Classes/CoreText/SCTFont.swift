//
//  SCTFont.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/9.
//

import Foundation

open class SCTFont: NSObject {
    
    public let font: CTFont
    
    open override var description: String {
        return "\(font)"
    }
    
    open override var debugDescription: String {
        return "\(font)"
    }
    
    public init(font: CTFont) {
        self.font = font
        super.init()
    }
    
    public init(font: UIFont) {
        self.font = font
        super.init()
    }
    
    public func getGlyphsForCharacters(characters: UnsafePointer<UniChar>,
                                glyphs: UnsafeMutablePointer<CGGlyph>,
                                count: CFIndex) -> Bool {
        return CTFontGetGlyphsForCharacters(font, characters, glyphs, count)
    }
    
    public func getGlyphsForString(string: CFString,
                            glyphs: UnsafeMutablePointer<CGGlyph>) -> Bool {
        let count = CFStringGetLength(string)
        var characters: [UniChar] = .init(repeating: UniChar(), count: count)
        CFStringGetCharacters(string, CFRange(location: 0, length: count), &characters)
        return CTFontGetGlyphsForCharacters(font, characters, glyphs, count)
    }
    
    public func getGlyphsForString(string: CFString) -> [CGGlyph]? {
        let count = CFStringGetLength(string)
        var glyphs: [CGGlyph] = .init(repeating: CGGlyph(), count: count)
        var characters: [UniChar] = .init(repeating: UniChar(), count: count)
        CFStringGetCharacters(string, CFRange(location: 0, length: count), &characters)
        let result = CTFontGetGlyphsForCharacters(font, characters, &glyphs, count)
        if result {
            return glyphs
        } else {
            return nil
        }
    }
    
    public func getGlyphsForString(string: String) -> [CGGlyph]? {
        return self.getGlyphsForString(string: string as CFString)
    }
    
    public func getGlyphsForString(string: NSAttributedString) -> [CGGlyph]? {
        return self.getGlyphsForString(string: string.string as CFString)
    }
    
    public func getBoundingRectsForGlyphs(orientation: CTFontOrientation,
                                   glyphs: UnsafePointer<CGGlyph>,
                                   boundingRects: UnsafeMutablePointer<CGRect>?,
                                   count: CFIndex) -> CGRect {
        return CTFontGetBoundingRectsForGlyphs(font, orientation, glyphs, boundingRects, count)
    }
    
}
