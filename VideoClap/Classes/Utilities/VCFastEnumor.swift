//
//  VCFastEnumor.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/27.
//

import Foundation

public protocol VCFastEnum: NSObject {
    var id: String { get set }
}

public class VCFastEnumor<T: VCFastEnum>: NSObject {
    
    private var fastEnum: [String:T] = [:]
    
    public init(group: [T]) {
        for item in group {
            fastEnum[item.id] = item
        }
    }
    
    public func object(id: String) -> T? {
        return fastEnum[id]
    }
    
}
