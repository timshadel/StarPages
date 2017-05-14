//
//  Request.swift
//  Interview
//
//  Created by Tim on 5/13/17.
//  Copyright © 2017 Day Logger, Inc. All rights reserved.
//

import Foundation


/// A small value that models the state of a request. This is most useful for the UI to render differently
/// depending on the current state of some request. It is not used for communicating errors. Do that with
/// the code that actually issues the request and processes the response.
enum Request<Value> {
    case waiting(since: Date)
    case resolved(Value)
    case failed
}
