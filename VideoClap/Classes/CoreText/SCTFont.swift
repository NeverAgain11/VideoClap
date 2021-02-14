//
//  SCTFont.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/9.
//

import Foundation

class SCTFont: NSObject {
    
    let font: CTFont
    
    override var description: String {
        return "\(font)"
    }
    
    override var debugDescription: String {
        return "\(font)"
    }
    
    init(font: CTFont) {
        self.font = font
        super.init()
    }
    
    init(font: UIFont) {
        self.font = font
        super.init()
    }
    
    func getGlyphsForCharacters(characters: UnsafePointer<UniChar>,
                                glyphs: UnsafeMutablePointer<CGGlyph>,
                                count: CFIndex) -> Bool {
        return CTFontGetGlyphsForCharacters(font, characters, glyphs, count)
    }
    
    func getGlyphsForString(string: CFString,
                            glyphs: UnsafeMutablePointer<CGGlyph>) -> Bool {
        let count = CFStringGetLength(string)
        var characters: [UniChar] = .init(repeating: UniChar(), count: count)
        CFStringGetCharacters(string, CFRange(location: 0, length: count), &characters)
        return CTFontGetGlyphsForCharacters(font, characters, glyphs, count)
    }
    
    func getGlyphsForString(string: CFString) -> [CGGlyph]? {
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
    
    func getGlyphsForString(string: String) -> [CGGlyph]? {
        return self.getGlyphsForString(string: string as CFString)
    }
    
    func getGlyphsForString(string: NSAttributedString) -> [CGGlyph]? {
        return self.getGlyphsForString(string: string.string as CFString)
    }
    
    func getBoundingRectsForGlyphs(orientation: CTFontOrientation,
                                   glyphs: UnsafePointer<CGGlyph>,
                                   boundingRects: UnsafeMutablePointer<CGRect>?,
                                   count: CFIndex) -> CGRect {
        return CTFontGetBoundingRectsForGlyphs(font, orientation, glyphs, boundingRects, count)
    }
    
}
