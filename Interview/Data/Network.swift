//
//  Network.swift
//  Interview
//
//  Created by Tim on 5/8/17.
//  Copyright © 2017 Day Logger, Inc. All rights reserved.
//

import Foundation
import UIKit


struct Network {

    /// These errors come from the HTTP response of the server, and indicate a problem with this
    /// specific request. Therefore, these should be handled by the requesting view. Other errors
    /// which indicate widespread unavailability of the service are handled generally.
    enum RequestError: LocalizedError {
        // HTTP client errors
        case badRequest(detail: JSONObject?)
        case notFound
        case unprocessibleEntity(detail: JSONObject?)
    }

    enum ProgrammingError: LocalizedError {
        case responseNotHTTP
    }


    static let general = Network(configuration: URLSessionConfiguration.default)

    private var session: URLSession
    private var sessionConfiguration: URLSessionConfiguration


    init(configuration: URLSessionConfiguration) {
        sessionConfiguration = configuration
        session = URLSession(configuration: configuration)
    }

    func getData(from url: URL, done: @escaping (Resolver<Data>) -> Void) {
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { done(Resolver(error: error)) }
                return
            }
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async { done(Resolver(error: Network.ProgrammingError.responseNotHTTP)) }
                return
            }
            switch response.statusCode {
            case 400, 422:
                DispatchQueue.main.async { done(Resolver(error: RequestError.badRequest(detail: data.map(self.forceJSON)))) }
            case 404, 410:
                DispatchQueue.main.async { done(Resolver(error: RequestError.notFound)) }
            case 200..<300:
                DispatchQueue.main.async { done(Resolver(value: data)) }
            default:
                // TODO: What about other status codes?
                DispatchQueue.main.async { done(Resolver(value: data)) }
            }
        }
        task.resume()
    }

    func getImage(from url: URL, done: @escaping (Resolver<UIImage>) -> Void) {
        getData(from: url) { resolver in
            do {
                let image = UIImage(data: try resolver.value())
                done(Resolver(value: image))
            } catch {
                done(Resolver(error: error))
            }
        }
    }

    func getJSON(from url: URL, done: @escaping (Resolver<JSONObject>) -> Void) {
        getData(from: url) { resolver in
            resolver.map(done) { data in try data.map(JSONObject.from) }
        }
    }

    private func forceJSON(from data: Data) -> JSONObject {
        if let obj = try? JSONObject.from(data) {
            return obj
        } else if let detail = String(data: data, encoding: .utf8) {
            return [ "responseBody": detail ]
        } else {
            return [ "responseBytes": data.description ]
        }
    }

}

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


enum Request<Value> {
    case ready
    case waiting(since: Date)
    case resolved(Value)
    case failed
}
