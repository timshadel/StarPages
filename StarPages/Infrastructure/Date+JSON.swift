//
//  Date+Extensions.swift
//  Interview
//
//  Created by Tim on 5/4/17.
//  Copyright © 2017 Day Logger, Inc. All rights reserved.
//

import Foundation


extension Date: CustomJSONValue {

    static fileprivate let YearMonthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let tz = TimeZone(abbreviation:"GMT")
        formatter.timeZone = tz
        return formatter
    }()

    init(object: Any) throws {
        guard let dateString = object as? String else {
            throw JSONError.typeMismatch(expected: String.self, actual: type(of: object))
        }
        guard let dateValue = Date.YearMonthDayFormatter.date(from: dateString) else {
            throw JSONError.typeMismatch(expected: "valid Date", actual: dateString)
        }
        self = dateValue
    }

    var jsonValue: Any {
        return Date.YearMonthDayFormatter.string(from: self)
    }
    
}
