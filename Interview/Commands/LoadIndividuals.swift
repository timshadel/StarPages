//
//  LoadIndividuals.swift
//  Interview
//
//  Created by Tim on 5/8/17.
//  Copyright © 2017 Day Logger, Inc. All rights reserved.
//

import Foundation


struct LoadIndividuals {

    var database: Database = JSONDatabase.shared

    func execute() {
        database.update(with: [
            MockData.luke
        ])
    }

}
