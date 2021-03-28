//
//  SCTFramesetter.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/9.
//

import Foundation
import CoreText

open class SCTFramesetter: NSObject {
    
    public let attrString: NSAttributedString
    public let framesetter: CTFramesetter
    
    open override var description: String {
        return "\(framesetter)"
    }
    
    open override var debugDescription: String {
        return "\(framesetter)"
    }
    
    public init(attrString: NSAttributedString) {
        self.attrString = attrString
        self.framesetter = CTFramesetterCreateWithAttributedString(attrString)
        super.init()
    }
    
    public init(attrString: CFAttributedString) {
        self.attrString = attrString
        self.framesetter = CTFramesetterCreateWithAttributedString(attrString)
        super.init()
    }
    
    public static func getTypeID() -> CFTypeID {
        return CTFramesetterGetTypeID()
    }
    
    public func createFrame(stringRange: CFRange, path: CGPath, frameAttributes: NSDictionary?) -> SCTFrame {
        let ctFrame = CTFramesetterCreateFrame(framesetter, stringRange, path, frameAttributes)
        return SCTFrame(framesetter: self, ctFrame: ctFrame, attrString: attrString)
    }
    
    public func createFrame() -> SCTFrame {
        let size = self.size()
        let framePath = CGMutablePath(rect: CGRect(origin: .zero, size: size), transform: nil)
        let ctFrame = CTFramesetterCreateFrame(framesetter, CFRange(), framePath, nil)
        return SCTFrame(framesetter: self, ctFrame: ctFrame, attrString: attrString)
    }
    
    public func getTypesetter() -> CTTypesetter {
        return CTFramesetterGetTypesetter(framesetter)
    }
    
    public func suggestFrameSizeWithConstraints(stringRange: CFRange,
                                         frameAttributes: NSDictionary?,
                                         constraints: CGSize,
                                         fitRange: UnsafeMutablePointer<CFRange>?) -> CGSize {
        return CTFramesetterSuggestFrameSizeWithConstraints(framesetter, stringRange, frameAttributes, constraints, fitRange)
    }
    
    public func size() -> CGSize {
        return self.suggestFrameSizeWithConstraints(stringRange: CFRange(), frameAttributes: nil, constraints: CGSize(width: .max, height: .max), fitRange: nil)
    }
    
}
