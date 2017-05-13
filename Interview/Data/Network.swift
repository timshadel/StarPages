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
                done(Resolver(error: error))
                return
            }
            guard let response = response as? HTTPURLResponse else {
                done(Resolver(error: Network.ProgrammingError.responseNotHTTP))
                return
            }
            switch response.statusCode {
            case 400, 422:
                done(Resolver(error: RequestError.badRequest(detail: data.map(self.forceJSON))))
            case 404, 410:
                done(Resolver(error: RequestError.notFound))
            case 200..<300:
                done(Resolver(value: data))
            default:
                // TODO: What about other status codes?
                done(Resolver(value: data))
            }
        }
        task.resume()
    }

    func getImage(from url: URL, done: @escaping (Resolver<UIImage>) -> Void) {
        getData(from: url) { resolver in
            do {
                let image = try resolver.value().flatMap { UIImage(data: $0) }
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

    func value() throws -> Value? {
        if let error = error {
            throw error
        }
        return privateValue
    }

    func map<T>(_ done: (Resolver<T>) -> Void, transform: (Value?) throws -> T?) {
        do {
            let result = try transform(try value())
            done(Resolver<T>(value: result))
        } catch {
            done(Resolver<T>(error: error))
        }
    }

}

extension URL {

    func getData(done: @escaping (Resolver<Data>) -> Void) {
        Network.general.getData(from: self) { r in done(r) }
    }

    func getImage(done: @escaping (Resolver<UIImage>) -> Void) {
        Network.general.getImage(from: self) { r in done(r) }
    }

    func getJSON(done: @escaping (Resolver<JSONObject>) -> Void) {
        Network.general.getJSON(from: self) { r in done(r) }
    }

}


// MARK: - Playground

protocol ResolverP {
    associatedtype ValueType
    init(value: ValueType?)
    init(error: Error)
    func value() throws -> ValueType?
}


struct SimpleResolver<Value>: ResolverP {
    typealias ValueType = Value

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

    func value() throws -> Value? {
        if let error = error {
            throw error
        }
        return privateValue
    }
    
}

protocol DataValue {
    static func value(from data: Data) throws -> Self?
}


class Request<Value> {

    enum State {
        case ready
        case waiting(since: Date)
        case done
    }

    var url: URL
    var state: State
    private var value: Value?
    private var error: Error?

    init(url: URL) {
        self.url = url
        self.state = .ready
    }

    func execute() {
        self.state = .waiting(since: Date())
        Network.general.getData(from: url) { resolver in
            self.state = .done
            do {
                let data: Data? = try resolver.value()
//                self.value = try data.flatMap { try value(from: $0) }
//                self.error = error
            } catch {
                self.error = error
            }
        }
    }

}


extension UIImage: DataValue {

    static func value(from data: Data) throws -> Self? {
        return self.init(data: data)
    }

}
