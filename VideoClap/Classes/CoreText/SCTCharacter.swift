//
//  SCTCharacter.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/10.
//

import Foundation

open class SCTCharacter: NSObject {
    
    open override var debugDescription: String {
        return "character: \(character), frame: \(frame)"
    }
    
    open override var description: String {
        return "character: \(character), frame: \(frame)"
    }
    
    public let character: NSAttributedString
    public var frame: CGRect
    
    public init(character: NSAttributedString, frame: CGRect) {
        self.character = character
        self.frame = frame
        super.init()
    }
    
}
