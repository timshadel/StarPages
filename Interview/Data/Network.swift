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

    /// HTTP client errors
    enum ResponseError: LocalizedError {
        case responseNotHTTP
        case unexpectedStatus(code: Int, detail: Data?)
    }

    private static let successRange = 200..<300

    static let general = Network(configuration: URLSessionConfiguration.default)

    private var session: URLSession
    private var sessionConfiguration: URLSessionConfiguration


    init(configuration: URLSessionConfiguration = URLSessionConfiguration.default) {
        sessionConfiguration = configuration
        session = URLSession(configuration: configuration)
    }

    func getData(from url: URL, done: @escaping (Resolver<Data>) -> Void) {
        let task = session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    done(Resolver(error: error))
                    return
                }
                guard let response = response as? HTTPURLResponse else {
                    done(Resolver(error: ResponseError.responseNotHTTP))
                    return
                }
                switch response.statusCode {
                case Network.successRange:
                    done(Resolver(value: data))
                default:
                    done(Resolver(error: ResponseError.unexpectedStatus(code: response.statusCode, detail: data)))
                }
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

}
