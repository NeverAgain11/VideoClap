//
//  AttributedStringBuilder.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/7.
//

import Foundation

public class AttributedStringBuilder: NSObject {
    
    public internal(set) var text: String = ""
    
    private var items: [Item] = []
    
    class Item {
        var string: String = ""
        var attributes: [NSAttributedString.Key : Any] = [:]
        init(string: String, attributed: [NSAttributedString.Key : Any]) {
            self.string = string
            self.attributes = attributed
        }
    }
    
    public init(text: String = "") {
        super.init()
        self.text = text
    }
    
    public func addAttribute(key: NSAttributedString.Key, value: Any, text: String) -> AttributedStringBuilder {
        if let item = items.first(where: { $0.string == text }) {
            item.attributes.merge([key:value]) { (current, new) in return new }
        } else {
            let item = Item(string: text, attributed: [key : value])
            items.append(item)
        }
        return self
    }
    
    public func addAttribute(key: NSAttributedString.Key, value: Any) -> AttributedStringBuilder {
        if let item = items.first(where: { $0.string == text }) {
            item.attributes.merge([key:value]) { (current, new) in return new }
        } else {
            let item = Item(string: text, attributed: [key : value])
            items.append(item)
        }
        return self
    }
    
    public func addAttributes(value: [NSAttributedString.Key : Any], text: String) -> AttributedStringBuilder {
        if let item = items.first(where: { $0.string == text }) {
            item.attributes.merge(value) { (current, new) in return new }
        } else {
            let item = Item(string: text, attributed: value)
            items.append(item)
        }
        return self
    }
    
    public func addAttributes(value: [NSAttributedString.Key : Any]) -> AttributedStringBuilder {
        if let item = items.first(where: { $0.string == text }) {
            item.attributes.merge(value) { (current, new) in return new }
        } else {
            let item = Item(string: text, attributed: value)
            items.append(item)
        }
        return self
    }
    
    public func build() -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(string: self.text)
        for item in items {
            let range = (self.text as NSString).range(of: item.string)
            attributedString.addAttributes(item.attributes, range: range)
        }
        return attributedString
    }
    
}
