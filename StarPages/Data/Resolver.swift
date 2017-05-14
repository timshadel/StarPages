//
//  Resolver.swift
//  Interview
//
//  Created by Tim on 5/13/17.
//  Copyright © 2017 Day Logger, Inc. All rights reserved.
//

import Foundation


/// Capture the result of an asynchronous request
struct Resolver<Value> {

    enum ResolverError: Error, CustomStringConvertible {
        case missingRequiredValue

        var description: String {
            switch self {
            case .missingRequiredValue:
                return "Missing required value."
            }
        }

    }

    private let privateValue: Value?
    private var error: Error?

    init(value: Value?) {
        self.privateValue = value
        self.error = nil
    }

    init(error: Error) {
        self.privateValue = nil
        self.error = error
    }

    func optionalValue() throws -> Value? {
        if let error = error {
            throw error
        }
        return privateValue
    }

    func value() throws -> Value {
        guard let value = try optionalValue() else { throw ResolverError.missingRequiredValue }
        return value
    }

    func map<T>(_ done: (Resolver<T>) -> Void, transform: (Value?) throws -> T?) {
        do {
            let result = try transform(try optionalValue())
            done(Resolver<T>(value: result))
        } catch {
            done(Resolver<T>(error: error))
        }
    }
    
}
