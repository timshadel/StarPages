//
//  IndividualCell.swift
//  Interview
//
//  Created by Tim on 5/4/17.
//  Copyright © 2017 Day Logger, Inc. All rights reserved.
//

import Foundation
import UIKit


class IndividualCell: UITableViewCell {

    // MARK: - UI properties

    @IBOutlet weak var profilePicView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var teamLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!


    // MARK: - Configure cell

    func configure(with individual: Individual) {
        nameLabel.text = individual.fullName
        teamLabel.text = individual.affiliation.rawValue
        guard let imageRequest = individual.profileImageRequest else { return }
        switch imageRequest {
        case .waiting:
            loadingIndicator.startAnimating()
        case .failed:
            loadingIndicator.stopAnimating()
        case let .resolved(image):
            profilePicView.image = image
        }
    }

}
