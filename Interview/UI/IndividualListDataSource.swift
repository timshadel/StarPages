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
    var individuals = [Individual]()

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return individuals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: IndividualCell.self), for: indexPath) as! IndividualCell
        let individual = individuals[indexPath.row]
        cell.configure(with: individual)
        return cell
    }

}
