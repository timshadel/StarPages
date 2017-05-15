//
//  LoadIndividuals.swift
//  Interview
//
//  Created by Tim on 5/8/17.
//  Copyright © 2017 Day Logger, Inc. All rights reserved.
//

import Foundation


struct LoadIndividuals {

    // MARK: - Constants

    private static let directoryURL = URL(string: "https://edge.ldscdn.org/mobile/interview/directory")!


    // MARK: - Private properties

    var database: Database = JSONDatabase.shared


    // MARK: - Command

    func execute() {
        Network.general.getJSON(from: LoadIndividuals.directoryURL) { resolver in
            do {
                let directory = try resolver.value()
                let individuals: [Individual] = try directory.value(for: Keys.individuals)
                self.database.update(with: individuals)
            } catch {
                Logger.error("at=download-directory status=error url=\(LoadIndividuals.directoryURL) error=\(error)")
            }
        }
    }

}
