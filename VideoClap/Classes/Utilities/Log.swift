//
//  Log.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/15.
//

import SwiftyBeaver

private let _log: SwiftyBeaver.Type = {
//    #if DEBUG
    let console = ConsoleDestination()
    console.asynchronously = false
    console.format = "$C$L$c <$DHH:mm:ss.SSS> $n[$l] > $F: \(Thread.current) $T\n$M"
    SwiftyBeaver.addDestination(console)
//    #endif
    return SwiftyBeaver.self
}()

public class log {
    
    public static func debug(_ message: Any...,
                             file: String = #file,
                             _ function: String = #function,
                             line: Int = #line,
                             context: Any? = nil) {
        _log.debug(message, file, function, line: line, context: context)
    }
    
    public static func error(_ message: Any...,
                             file: String = #file,
                             _ function: String = #function,
                             line: Int = #line,
                             context: Any? = nil) {
        _log.error(message, file, function, line: line, context: context)
    }
    
    public static func warning(_ message: Any...,
                               file: String = #file,
                               _ function: String = #function,
                               line: Int = #line,
                               context: Any? = nil) {
        _log.warning(message, file, function, line: line, context: context)
    }
    
    public static func info(_ message: Any...,
                            file: String = #file,
                            _ function: String = #function,
                            line: Int = #line,
                            context: Any? = nil) {
        _log.info(message, file, function, line: line, context: context)
    }
    
    public static func verbose(_ message: Any...,
                               file: String = #file,
                               _ function: String = #function,
                               line: Int = #line,
                               context: Any? = nil) {
        _log.verbose(message, file, function, line: line, context: context)
    }
    
}
