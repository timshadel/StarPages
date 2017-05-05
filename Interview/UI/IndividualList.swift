//
//  IndividualList.swift
//  Interview
//
//  Created by Tim on 5/4/17.
//  Copyright © 2017 Day Logger, Inc. All rights reserved.
//

import UIKit

class IndividualList: UIViewController {

    @IBOutlet weak var emptyState: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dataSource: UITableViewDataSource!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        
    }

}


extension IndividualList: UITableViewDelegate {

}
