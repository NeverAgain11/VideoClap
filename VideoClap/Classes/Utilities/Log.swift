//
//  Log.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/15.
//

import SwiftyBeaver

internal let log: SwiftyBeaver.Type = {
//    #if DEBUG
    let console = ConsoleDestination()
    console.asynchronously = false
    console.format = "$C$L$c $n[$l] > $F: \(Thread.current) $T\n$M"
    SwiftyBeaver.addDestination(console)
//    #endif
    return SwiftyBeaver.self
}()
