//
//  Database.swift
//  Interview
//
//  Created by Tim on 5/4/17.
//  Copyright © 2017 Day Logger, Inc. All rights reserved.
//

import Foundation


protocol Database {
    var individuals: [Individual] { get }
    func subscribe(at: Subscriber)
    func unsubscribe(at: Subscriber)
    func update(with: [Individual])
}


protocol Subscriber: class {
    func update(with: Database)
}


class JSONDatabase: Database {

    // MARK: - Public properties

    static let shared = JSONDatabase()

    var individuals = [Individual]()


    // MARK: - Private properties

    private static let fileURL = FileManager.documentDirectory.appendingPathComponent("database.json")

    private var subscribers = [Subscriber]()


    // MARK: Database protocol

    func subscribe(at subscriber: Subscriber) {
        subscribers.append(subscriber)
        notify(subscriber)
    }

    func unsubscribe(at unsubscriber: Subscriber) {
        subscribers = subscribers.filter { $0 !== unsubscriber }
    }

    func update(with list: [Individual]) {
        individuals.removeAll()
        individuals.append(contentsOf: list)
        archive()
        notify()
    }

    func load() {
        do {
            let data = try Data(contentsOf: JSONDatabase.fileURL)
            let json = try JSONObject.from(data)
            self.individuals = try json.value(for: Keys.individuals)
            Logger.debug("at=database-load status=success individuals.count=\(individuals.count)")
        } catch let error as CocoaError {
            if case CocoaError.fileReadNoSuchFile = error.code {
                Logger.debug("at=database-load status=success individuals.count=0")
            } else {
                Logger.error("at=database-load status=error error.code=\(error.code.rawValue) error.description=\"\(error.localizedDescription)\" error.userInfo=\(error.userInfo)")
            }
        } catch {
            Logger.error("at=database-load status=error file=\(JSONDatabase.fileURL) error=\(error)")
        }
    }


    // MARK: - Helper functions

    private func notify() {
        for subscriber in subscribers {
            notify(subscriber)
        }
    }

    private func notify(_ subscriber: Subscriber) {
        DispatchQueue.main.async {
            subscriber.update(with: self)
        }
    }
    
    private func archive() {
        do {
            let json: JSONObject = [
                Keys.individuals: individuals.jsonObjects()
            ]
            let data = try json.jsonData()
            try data.write(to: JSONDatabase.fileURL, options: [.atomic])
            Logger.debug("at=database-archive status=success individuals.count=\(individuals.count) file=\(JSONDatabase.fileURL)")
        } catch {
            Logger.error("at=database-archive status=error individuals.count=\(individuals.count) file=\(JSONDatabase.fileURL) error=\(error)")
        }
    }

}
