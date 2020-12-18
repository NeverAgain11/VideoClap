//
//  String.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/18.
//

import Foundation

extension String {
    
    func appendingPathExtension(_ str: String) -> String? {
        return (self as NSString).appendingPathExtension(str)
    }
    
    func deletingPathExtension() -> String {
        return (self as NSString).deletingPathExtension
    }
    
    var pathExtension: String {
        return (self as NSString).pathExtension
    }
    
}
