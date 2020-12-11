//
//  VCLocker.swift
//  VideoClap
//
//  Created by lai001 on 2020/11/23.
//

import Foundation

public class VCLocker: NSObject {
    
    private var lockerDic: [String : NSLock] = [:]
    
    private var locker: NSLock = NSLock()
    
    public func object(forKey key: String) -> NSLock {
        locker.lock()
        defer {
            locker.unlock()
        }
        if let locker = lockerDic[key] {
            return locker
        } else {
            let locker = NSLock()
            lockerDic[key] = locker
            return locker
        }
    }
    
}
