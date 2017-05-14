//
//  MockData.swift
//  Interview
//
//  Created by Tim on 5/8/17.
//  Copyright © 2017 Day Logger, Inc. All rights reserved.
//

import Foundation


struct MockData {

    // MARK: JSON values

    static let lukeJSON: JSONObject = [
        "affiliation": "JEDI",
        "birthdate": "1963-05-05",
        "firstName": "Luke",
        "forceSensitive": true,
        "lastName": "Skywalker",
        "profilePicture": "https://edge.ldscdn.org/mobile/interview/07.png"
    ]


    // MARK: Unmarshaled values

    static let luke = try! Individual(json: lukeJSON)

}
