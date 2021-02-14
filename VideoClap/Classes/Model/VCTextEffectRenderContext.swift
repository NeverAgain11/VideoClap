//
//  VCTextEffectRenderContext.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/14.
//

import Foundation

public class VCTextEffectRenderContext {
    var text: NSMutableAttributedString = NSMutableAttributedString(string: "")
    var renderSize: CGSize = .zero
    var renderScale: CGFloat = .zero
    var characters: [SCTCharacter] = []
    var textSize: CGSize = .zero
    var progress: CGFloat = .zero
}
