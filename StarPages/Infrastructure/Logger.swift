//
//  Logger.swift
//  Interview
//
//  Created by Tim on 5/13/17.
//  Copyright © 2017 Day Logger, Inc. All rights reserved.
//

import Foundation


struct Logger {

    static private let loaded = Date()

    private enum Level: String {
        case debug
        case warn
        case error = "ERROR"
    }

    static func debug(_ msg: String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        log(msg, level: .debug, file: file, function: function, line: line)
    }

    static func warn(_ msg: String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        log(msg, level: .warn, file: file, function: function, line: line)
    }

    static func error(_ msg: String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        log(msg, level: .error, file: file, function: function, line: line)
    }

    private static func log(_ msg: String, level: Level = .debug, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        #if DEBUG
            let since = fabs(loaded.timeIntervalSinceNow)
            let sinceString = String(format: "%.3f", arguments: [since])
            let fileName = URL(string: String(describing: file))!.lastPathComponent
            let line = "t=\(sinceString) level=\(level.rawValue) in=\(fileName) fn=\(function) line=\(line) \(msg)"
            print(line)
        #endif
    }

}
