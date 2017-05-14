//
//  FileManager.swift
//  Interview
//
//  Created by Tim on 5/6/17.
//  Copyright © 2017 Day Logger, Inc. All rights reserved.
//

import Foundation


public extension FileManager {

    public static var documentDirectory: URL {
        return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }

    public static var cachesDirectory: URL {
        return try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }

}
