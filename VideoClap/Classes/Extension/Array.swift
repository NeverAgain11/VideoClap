//
//  Array.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/15.
//

import Foundation

extension Array {
    
    func object(at index: Int) -> Element? {
        if (0..<self.count).contains(index) {
            return self[index]
        } else {
            return nil
        }
    }
    
}
