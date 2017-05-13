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

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!


    // MARK: - Internal properties

    var individual: Individual?


    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
    }

    override func viewWillAppear(_ animated: Bool) {
        profileImageView.image = nil
        nameLabel.text = individual?.fullName
    }

}
