//
//  SCTFramesetter.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/9.
//

import Foundation
import CoreText

class SCTFramesetter: NSObject {
    
    let attrString: NSAttributedString
    let framesetter: CTFramesetter
    
    override var description: String {
        return "\(framesetter)"
    }
    
    override var debugDescription: String {
        return "\(framesetter)"
    }
    
    init(attrString: NSAttributedString) {
        self.attrString = attrString
        self.framesetter = CTFramesetterCreateWithAttributedString(attrString)
        super.init()
    }
    
    init(attrString: CFAttributedString) {
        self.attrString = attrString
        self.framesetter = CTFramesetterCreateWithAttributedString(attrString)
        super.init()
    }
    
    static func getTypeID() -> CFTypeID {
        return CTFramesetterGetTypeID()
    }
    
    func createFrame(stringRange: CFRange, path: CGPath, frameAttributes: NSDictionary?) -> SCTFrame {
        let ctFrame = CTFramesetterCreateFrame(framesetter, stringRange, path, frameAttributes)
        return SCTFrame(framesetter: self, ctFrame: ctFrame, attrString: attrString)
    }
    
    func createFrame() -> SCTFrame {
        let size = self.size()
        let framePath = CGMutablePath(rect: CGRect(origin: .zero, size: size), transform: nil)
        let ctFrame = CTFramesetterCreateFrame(framesetter, CFRange(), framePath, nil)
        return SCTFrame(framesetter: self, ctFrame: ctFrame, attrString: attrString)
    }
    
    func getTypesetter() -> CTTypesetter {
        return CTFramesetterGetTypesetter(framesetter)
    }
    
    func suggestFrameSizeWithConstraints(stringRange: CFRange,
                                         frameAttributes: NSDictionary?,
                                         constraints: CGSize,
                                         fitRange: UnsafeMutablePointer<CFRange>?) -> CGSize {
        return CTFramesetterSuggestFrameSizeWithConstraints(framesetter, stringRange, frameAttributes, constraints, fitRange)
    }
    
    func size() -> CGSize {
        return self.suggestFrameSizeWithConstraints(stringRange: CFRange(), frameAttributes: nil, constraints: CGSize(width: .max, height: .max), fitRange: nil)
    }
    
}
