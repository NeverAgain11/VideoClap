//
//  VCTextEffectRenderContext.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/14.
//

import Foundation

public class VCTextEffectRenderContext: NSObject {
    public var text: NSMutableAttributedString = NSMutableAttributedString(string: "")
    public var renderSize: CGSize = .zero
    public var renderScale: CGFloat = .zero
    public var characters: [SCTCharacter] = []
    public var textSize: CGSize = .zero
    public var progress: CGFloat = .zero
}
