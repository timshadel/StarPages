//
//  JSON.swift
//
//  Original Gist: https://gist.github.com/jarsen/b27de2ed9e84b84086ae
//
//  Blog post: http://jasonlarsen.me/2015/06/23/no-magic-json-pt2.html
//
//  Started with Marshal, but quickly morphed to just the good parts:
//      http://github.com/utahiosmac/Marshal
//
//  Curated and renamed by Tim.


import Foundation


// MARK: - Core Types

/// A JSON object is simply a dictionary whose key is a `String`.
typealias JSONObject = [String: Any]

/// Any type can be compatible with JSON.
protocol JSONCompatible: JSONValue, JSONSerializable {

    /// JSON types know how to initialize themselves from JSON objects.
    init(json: JSONObject) throws

    /// JSON types know how to update themselves from JSON objects. The default protocol
    ///   implementation replaces this object with a new one created using `init(json:)`.
    mutating func update(with: JSONObject) throws

    /// JSON types know how to convert themselves to JSON objects.
    func jsonObject() -> JSONObject

}

/// JSON values are types that can be saved in a JSON object. This includes primitives
///   like `Int` and `String`.
protocol JSONValue {
    init(object: Any) throws
}

/// Use this to make building JSONObjects easy.
protocol CustomJSONValue: JSONValue {
    var jsonValue: Any { get }
}

/// JSON objects or arrays can be converted to `Data`.
protocol JSONSerializable {

    /// Serialize this collection to Data
    func jsonData(pretty: Bool) throws -> Data

    /// UTF8-ecoded string representation of this collection
    func jsonString(pretty: Bool) throws -> String

}

enum JSONError: Error, CustomStringConvertible {

    case keyNotFound(key: String)
    case nullValue(key: String)
    case typeMismatch(expected: Any, actual: Any)
    case typeMismatchWithKey(key: String, expected: Any, actual: Any)
    case invalidUTF8Serialization(data: Data)
    case noUTF8Serialization(string: String)

    var description: String {
        switch self {
        case let .keyNotFound(key):
            return "Key not found: \(key)"
        case let .nullValue(key):
            return "Null Value found at: \(key)"
        case let .typeMismatch(expected, actual):
            return "Type mismatch. Expected type \(expected). Got '\(actual)'"
        case let .typeMismatchWithKey(key, expected, actual):
            return "Type mismatch. Expected type \(expected) for key: \(key). Got '\(actual)'"
        case let .invalidUTF8Serialization(data):
            return "Serialized JSON is not UTF8. \(data.count) bytes given."
        case let .noUTF8Serialization(string):
            return "JSON string cannot be saved as UTF8 bytes. \(string.characters.count) characters given."
        }
    }

}


// MARK: - JSON Serialization

extension JSONSerializable {
    func jsonData(pretty: Bool = true) throws -> Data {
        var subject: Any = self
        if let value = self as? JSONCompatible {
            subject = value.jsonObject()
        }
        var options: JSONSerialization.WritingOptions = []
        if pretty {
            options.insert(.prettyPrinted)
        }
        return try JSONSerialization.data(withJSONObject: subject, options: options)
    }

    func jsonString(pretty: Bool = true) throws -> String {
        let data = try jsonData(pretty: pretty)
        guard let result = String(data: data, encoding: .utf8) else {
            throw JSONError.invalidUTF8Serialization(data: data)
        }
        return result
    }
}

extension Dictionary : JSONSerializable {
    static func json(from data: Data) throws -> JSONObject {
        let object: Any = try JSONSerialization.jsonObject(with: data, options: [])
        guard let objectValue = object as? JSONObject else {
            throw JSONError.typeMismatch(expected: JSONObject.self, actual: type(of: object))
        }
        return objectValue
    }

    static func json(from string: String) throws -> JSONObject {
        guard let data = string.data(using: .utf8) else {
            throw JSONError.noUTF8Serialization(string: string)
        }
        return try json(from: data)
    }
}

extension Dictionary where Key == String, Value: Any {
    static func from(_ data: Data) throws -> JSONObject {
        return try json(from: data)
    }

    static func from(_ string: String) throws -> JSONObject {
        return try json(from: string)
    }
}

extension Array : JSONSerializable {
    static func json(from data: Data) throws -> [JSONObject] {
        let object: Any = try JSONSerialization.jsonObject(with: data, options: [])
        guard let array = object as? [JSONObject] else {
            throw JSONError.typeMismatch(expected: [JSONObject].self, actual: type(of: object))
        }
        return array
    }

    static func json(from string: String) throws -> [JSONObject] {
        guard let data = string.data(using: .utf8) else {
            throw JSONError.noUTF8Serialization(string: string)
        }
        return try json(from: data)
    }
}

extension Set : JSONSerializable {}


// MARK: - Storage

/// This is where the magic happens. Since a JSONObject is just a Dictionary, accessing JSON
/// values is simply implemented with extensions to Dictionary.
extension Dictionary {

    // MARK: Base Value Accessors

    func optionalAny(for key: String) -> Any? {
        guard let aKey = key as? Key else { return nil }
        return self[aKey]
    }

    func any(for key: String) throws -> Any {
        let pathComponents = key.characters.split(separator: ".").map(String.init)
        var accumulator: Any = self

        for component in pathComponents {
            if let componentData = accumulator as? Dictionary, let value = componentData.optionalAny(for: component) {
                accumulator = value
                continue
            }
            throw JSONError.keyNotFound(key: key)
        }

        if let _ = accumulator as? NSNull {
            throw JSONError.nullValue(key: key)
        }

        return accumulator
    }


    // MARK: Single Item with Default

    func value<A: JSONValue>(for key: String, or item: A) throws -> A {
        let possible: A? = try self.value(for: key)
        return possible ?? item
    }

    func value(for key: String, or item: JSONObject) throws -> JSONObject {
        let possible: JSONObject? = try self.value(for: key)
        return possible ?? item
    }

    func value<A: RawRepresentable>(for key: String, or item: A) throws -> A where A.RawValue: JSONValue {
        let possible: A? = try self.value(for: key)
        return possible ?? item
    }


    // MARK: Single Item

    func value<A: JSONValue>(for key: String) throws -> A {
        let any = try self.any(for: key)
        do {
            return try A(object: any)
        } catch let JSONError.typeMismatch(expected: expected, actual: actual) {
            throw JSONError.typeMismatchWithKey(key: key, expected: expected, actual: actual)
        }
    }

    func value<A: JSONValue>(for key: String) throws -> A? {
        do {
            return try self.value(for: key) as A
        } catch JSONError.keyNotFound {
            return nil
        } catch JSONError.nullValue {
            return nil
        }
    }

    func value(for key: String) throws -> JSONObject {
        let any = try self.any(for: key)
        guard let object = any as? JSONObject else {
            throw JSONError.typeMismatchWithKey(key: key, expected: JSONObject.self, actual: type(of: any))
        }
        return object
    }

    func value(for key: String) throws -> JSONObject? {
        do {
            return try value(for: key) as JSONObject
        } catch JSONError.keyNotFound {
            return nil
        } catch JSONError.nullValue {
            return nil
        }
    }

    func value<A: RawRepresentable>(for key: String) throws -> A where A.RawValue: JSONValue {
        let raw: A.RawValue = try self.value(for: key)
        guard let value = A(rawValue: raw) else {
            throw JSONError.typeMismatchWithKey(key: key, expected: A.self, actual: raw)
        }
        return value
    }

    func value<A: RawRepresentable>(for key: String) throws -> A? where A.RawValue: JSONValue {
        do {
            return try self.value(for: key) as A
        } catch JSONError.keyNotFound {
            return nil
        } catch JSONError.nullValue {
            return nil
        }
    }


    // MARK: Array of Items

    func value<A: JSONValue>(for key: String, discardingErrors: Bool = false) throws -> [A] {
        let any = try self.any(for: key)
        do {
            return try Array<A>.value(from: any, discardingErrors: discardingErrors)
        } catch let JSONError.typeMismatch(expected: expected, actual: actual) {
            throw JSONError.typeMismatchWithKey(key: key, expected: expected, actual: actual)
        }
    }

    func value<A: JSONValue>(for key: String, discardingErrors: Bool = false) throws -> [A]? {
        do {
            return try self.value(for: key, discardingErrors: discardingErrors) as [A]
        } catch JSONError.keyNotFound {
            return nil
        } catch JSONError.nullValue {
            return nil
        }
    }

    func value<A: JSONValue>(for key: String) throws -> [A?] {
        let any = try self.any(for: key)
        do {
            return try Array<A>.value(from: any)
        } catch let JSONError.typeMismatch(expected: expected, actual: actual) {
            throw JSONError.typeMismatchWithKey(key: key, expected: expected, actual: actual)
        }
    }

    func value<A: JSONValue>(for key: String) throws -> [A?]? {
        do {
            return try self.value(for: key) as [A]
        } catch JSONError.keyNotFound {
            return nil
        } catch JSONError.nullValue {
            return nil
        }
    }

    func value(for key: String) throws -> [JSONObject] {
        let any = try self.any(for: key)
        guard let object = any as? [JSONObject] else {
            throw JSONError.typeMismatchWithKey(key: key, expected: [JSONObject].self, actual: type(of: any))
        }
        return object
    }

    func value(for key: String) throws -> [JSONObject]? {
        do {
            return try value(for: key) as [JSONObject]
        } catch JSONError.keyNotFound {
            return nil
        } catch JSONError.nullValue {
            return nil
        }
    }


    // MARK: Dictionary of Items

    func value<A: JSONValue>(for key: String) throws -> [String: A] {
        let any = try self.any(for: key)
        do {
            return try [String: A].value(from: any)
        } catch let JSONError.typeMismatch(expected: expected, actual: actual) {
            throw JSONError.typeMismatchWithKey(key: key, expected: expected, actual: actual)
        }
    }

    func value<A: JSONValue>(for key: String) throws -> [String: A]? {
        do {
            let any = try self.any(for: key)
            return try [String: A].value(from: any)
        } catch JSONError.keyNotFound {
            return nil
        } catch JSONError.nullValue {
            return nil
        }
    }

    func value<A: RawRepresentable>(for key: String) throws -> [A] where A.RawValue: JSONValue {
        let rawArray = try self.value(for: key) as [A.RawValue]
        return try rawArray.map({ raw in
            guard let value = A(rawValue: raw) else {
                throw JSONError.typeMismatchWithKey(key: key, expected: A.self, actual: raw)
            }
            return value
        })
    }

    func value<A: RawRepresentable>(for key: String) throws -> [A]? where A.RawValue: JSONValue {
        do {
            return try self.value(for: key) as [A]
        } catch JSONError.keyNotFound {
            return nil
        } catch JSONError.nullValue {
            return nil
        }
    }


    // MARK: Set of Items

    func value<A: RawRepresentable>(for key: String) throws -> Set<A> where A.RawValue: JSONValue {
        let rawArray = try self.value(for: key) as [A.RawValue]
        let enumArray: [A] = try rawArray.map({ raw in
            guard let value = A(rawValue: raw) else {
                throw JSONError.typeMismatchWithKey(key: key, expected: A.self, actual: raw)
            }
            return value
        })
        return Set<A>(enumArray)
    }

    func value<A: RawRepresentable>(for key: String) throws -> Set<A>? where A.RawValue: JSONValue {
        do {
            return try self.value(for: key) as Set<A>
        } catch JSONError.keyNotFound {
            return nil
        } catch JSONError.nullValue {
            return nil
        }
    }

}

extension URL: CustomJSONValue {
    init(object: Any) throws {
        guard let urlString = object as? String else {
            throw JSONError.typeMismatch(expected: String.self, actual: type(of: object))
        }
        guard let url = URL(string: urlString) else {
            throw JSONError.typeMismatch(expected: "valid URL", actual: urlString)
        }
        self = url
    }

    var jsonValue: Any {
        return self.absoluteString
    }
}


// MARK: - JSONCompatible Arrays

extension Array where Element: JSONCompatible {
    func jsonObjects() -> [JSONObject] {
        return map { $0.jsonObject() }
    }
}


// MARK: - Default Implementations

extension JSONCompatible {
    init(object: Any) throws {
        guard let convertedObject = object as? JSONObject else {
            throw JSONError.typeMismatch(expected: JSONObject.self, actual: type(of: object))
        }
        try self.init(json: convertedObject)
    }

    mutating func update(with object: JSONObject) throws {
        self = try type(of: self).init(json: object)
    }
}


extension JSONValue {
    init(object: Any) throws {
        guard let objectValue = object as? Self else {
            throw JSONError.typeMismatch(expected: Self.self, actual: type(of: object))
        }
        self = objectValue
    }
}

extension String: JSONValue {}
extension Int: JSONValue {}
extension UInt: JSONValue {}
extension Float: JSONValue {}
extension Double: JSONValue {}
extension Bool: JSONValue {}


// MARK: - Private implementations

fileprivate extension Array where Element: JSONValue {
    static func value(from object: Any, discardingErrors: Bool = false) throws -> [Element] {
        guard let anyArray = object as? [Any] else {
            throw JSONError.typeMismatch(expected: self, actual: type(of: object))
        }

        if discardingErrors {
            return anyArray.flatMap { try? Element(object: $0) }
        } else {
            return try anyArray.map { try Element(object: $0) }
        }
    }

    static func value(from object: Any) throws -> [Element?] {
        guard let anyArray = object as? [Any] else {
            throw JSONError.typeMismatch(expected: self, actual: type(of: object))
        }
        return anyArray.map {
            return try? Element(object: $0)
        }
    }
}

fileprivate extension Dictionary where Value: JSONValue {
    static func value(from object: Any) throws -> Dictionary<Key, Value> {
        guard let objectValue = object as? [Key: Any] else {
            throw JSONError.typeMismatch(expected: self, actual: type(of: object))
        }
        var result = [Key:Value]()
        for (k, v) in objectValue {
            result[k] = try Value(object: v)
        }
        return result
    }
}
