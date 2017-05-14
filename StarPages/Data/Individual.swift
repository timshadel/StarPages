//
//  Individual.swift
//  Interview
//
//  Created by Tim on 5/4/17.
//  Copyright © 2017 Day Logger, Inc. All rights reserved.
//

import Foundation
import UIKit


enum Affiliation: String {
    case jedi = "JEDI"
    case resistance = "RESISTANCE"
    case firstOrder = "FIRST_ORDER"
    case sith = "SITH"
}


struct Individual: JSONCompatible {

    let firstName: String
    let lastName: String
    let affiliation: Affiliation
    let birthdate: Date
    let forceSensitive: Bool
    let profilePictureURL: URL
    var profileImage: UIImage?
    var fullName: String {
        return "\(firstName) \(lastName)"
    }

    init(json: JSONObject) throws {
        self.firstName = try json.value(for: Keys.firstName)
        self.lastName = try json.value(for: Keys.lastName)
        self.affiliation = try json.value(for: Keys.affiliation)
        self.birthdate = try json.value(for: Keys.birthdate)
        self.forceSensitive = try json.value(for: Keys.forceSensitive)
        self.profilePictureURL = try json.value(for: Keys.profilePicture)
    }

    func jsonObject() -> JSONObject {
        return [
            Keys.firstName: firstName,
            Keys.lastName: lastName,
            Keys.affiliation: affiliation.rawValue,
            Keys.birthdate: birthdate.jsonValue,
            Keys.forceSensitive: forceSensitive,
            Keys.profilePicture: profilePictureURL.jsonValue
        ]
    }

}
