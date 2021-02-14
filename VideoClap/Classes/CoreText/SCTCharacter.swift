//
//  SCTCharacter.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/10.
//

import Foundation

class SCTCharacter: NSObject {
    
    override var debugDescription: String {
        return "character: \(character), frame: \(frame)"
    }
    
    override var description: String {
        return "character: \(character), frame: \(frame)"
    }
    
    let character: NSAttributedString
    var frame: CGRect
    
    init(character: NSAttributedString, frame: CGRect) {
        self.character = character
        self.frame = frame
        super.init()
    }
    
}
