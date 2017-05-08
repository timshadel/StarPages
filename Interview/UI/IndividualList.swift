//
//  IndividualList.swift
//  Interview
//
//  Created by Tim on 5/4/17.
//  Copyright © 2017 Day Logger, Inc. All rights reserved.
//

import UIKit

class IndividualList: UIViewController {

    // MARK: - UI Properties

    @IBOutlet weak var emptyState: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dataSource: IndividualListDataSource!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: UIControlEvents.valueChanged)
        return refreshControl
    }()


    // MARK: - Internal properties

    var database: Database = JSONDatabase.shared
    var command: LoadIndividuals?


    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        tableView.tableFooterView = UIView()
        tableView.addSubview(refreshControl)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        database.subscribe(at: self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        database.unsubscribe(at: self)
        super.viewDidDisappear(animated)
    }


    // MARK: - Load List

    func handleRefresh() {
        loadIndividuals()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func loadIndividuals() {
        command = LoadIndividuals()
        command?.execute()
    }


    // MARK: - Manage Loading, Empty, and List States

    fileprivate func showEmptyState() {
        tableView.backgroundView = emptyState
        loadingLabel.text = Strings.noIndividualsLoaded
        activityIndicator.stopAnimating()
    }

    fileprivate func showLoadingState() {
        tableView.backgroundView = emptyState
        loadingLabel.text = Strings.loading
        activityIndicator.startAnimating()
    }

    fileprivate func showIndividualListState() {
        tableView.backgroundView = nil
        showEmptyState()
    }

}


extension IndividualList: UITableViewDelegate {

}


// MARK: - Unidirectional Data Flow

extension IndividualList: Subscriber {

    func update(with database: Database) {
        dataSource.individuals = database.individuals
        if dataSource.individuals.count == 0 {
            showEmptyState()
        } else {
            showIndividualListState()
        }
        refreshControl.endRefreshing()
        tableView.reloadData()
    }

}
