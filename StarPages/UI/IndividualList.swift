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

    var refreshControl: UIRefreshControl = {
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
        handleRefresh()
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
        showEmptyState()
        tableView.backgroundView = nil
    }

}


// MARK: - Table view methods

extension IndividualList: UITableViewDelegate {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? IndividualDetails, let indexPath = tableView.indexPathForSelectedRow {
            destination.individual = dataSource.item(at: indexPath)
        }
    }

}


// MARK: - Unidirectional Data Flow

extension IndividualList: Subscriber {

    func update(with database: Database) {
        if database.individuals.count == 0 {
            dataSource.save(individuals: [])
            dataSource.imageRequests = [:]
            showEmptyState()
            Logger.debug("at=update-list status=empty")
        } else {
            dataSource.save(individuals: database.individuals)
            for index in 0..<dataSource.count {
                let individual = dataSource.item(at: IndexPath(row: index, section: 0))
                let imageURL = individual.profilePictureURL
                guard dataSource.imageRequests[imageURL] == nil else { continue }
                dataSource.imageRequests[imageURL] = .waiting(since: Date())
                Network.general.getImage(from: imageURL) { resolver in
                    do {
                        self.dataSource.imageRequests[imageURL] = .resolved(try resolver.value())
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                        Logger.debug("at=process-image status=success url=\(imageURL)")
                    } catch {
                        self.dataSource.imageRequests[imageURL] = .failed
                        Logger.error("at=process-image status=error url=\(imageURL) error=\(error)")
                    }
                }
            }
            showIndividualListState()
            Logger.debug("at=update-list count=\(dataSource.count)")
        }
        refreshControl.endRefreshing()
        tableView.reloadData()
    }

}
