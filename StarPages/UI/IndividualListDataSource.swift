//
//  IndividualListDataSource.swift
//  Interview
//
//  Created by Tim on 5/4/17.
//  Copyright © 2017 Day Logger, Inc. All rights reserved.
//

import Foundation
import UIKit


class IndividualListDataSource: NSObject, UITableViewDataSource {

    // MARK: - Data access

    var imageRequests = [URL:Request<UIImage>]() {
        didSet {
            resolveImages()
        }
    }

    var count: Int {
        return individuals.count
    }

    func item(at path: IndexPath) -> Individual {
        return resolved[path.row]
    }

    func save(individuals: [Individual]) {
        self.individuals = individuals
    }


    // MARK: - Private properties

    private var individuals = [Individual]() {
        didSet {
            resolveImages()
        }
    }

    /// List of individuals with images attached
    private var resolved = [Individual]()


    // MARK: - Table view methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return individuals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: IndividualCell.self), for: indexPath) as! IndividualCell
        let individual = item(at: indexPath)
        cell.configure(with: individual)
        return cell
    }


    // MARK: - Helper methods

    private func resolveImages() {
        resolved = individuals.map { individual in
            guard let request = imageRequests[individual.profilePictureURL] else { return individual }
            var person = individual
            person.profileImageRequest = request
            return person
        }
    }

}
