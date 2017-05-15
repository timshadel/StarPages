//
//  IndividualDetails.swift
//  Interview
//
//  Created by Tim on 5/13/17.
//  Copyright © 2017 Day Logger, Inc. All rights reserved.
//

import Foundation
import UIKit


class IndividualDetails: UIViewController {

    // MARK: - UI properties

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var teamLabel: UILabel!


    // MARK: - Internal properties

    var individual: Individual?


    // MARK: - Lifecycle Methods

    override func viewDidLayoutSubviews() {
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
    }

    override func viewWillAppear(_ animated: Bool) {
        profileImageView.image = individual?.profileImageRequest?.value()
        nameLabel.text = individual?.fullName
        teamLabel.text = individual?.affiliation.rawValue
    }

}
