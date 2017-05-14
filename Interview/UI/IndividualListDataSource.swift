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

    /// List of individuals that will be displayed
    var individuals = [Individual]() {
        didSet {
            resolveImages()
        }
    }

    /// Simple cache of images
    var imageRequests = [URL:Request<UIImage>]() {
        didSet {
            resolveImages()
        }
    }

    /// List of individuals with images
    private var resolved = [Individual]()

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return individuals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: IndividualCell.self), for: indexPath) as! IndividualCell
        let individual = item(at: indexPath)
        cell.configure(with: individual)
        return cell
    }

    func item(at path: IndexPath) -> Individual {
        return resolved[path.row]
    }
    
    private func resolveImages() {
        resolved = individuals.map { individual in
            guard let request = imageRequests[individual.profilePictureURL] else { return individual }
            var person = individual
            switch request {
            case .waiting:
                // Could show spinner, or pulse like Facebook instead
                break
            case let .resolved(image):
                person.profileImage = image
            case .failed:
                person.profileImage = nil
            }
            return person
        }
    }

}
