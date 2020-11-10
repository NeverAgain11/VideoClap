//
//  FastEnumor.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/27.
//

import Foundation

internal protocol FastEnum: NSObject {
    var id: String { get set }
}

internal class FastEnumor<T: FastEnum>: NSObject {
    
    private var fastEnum: [String:T] = [:]
    
    init(group: [T]) {
        for item in group {
            fastEnum[item.id] = item
        }
    }
    
    func get(id: String) -> T? {
        return fastEnum[id]
    }
    
}
