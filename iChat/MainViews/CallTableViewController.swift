//
//  CallTableViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 2019-08-08.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import ProgressHUD
import FirebaseFirestore

class CallTableViewController: UITableViewController, UISearchResultsUpdating {
    var allCalls: [CallClass] = []
    var filteredCalls: [CallClass] = []
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let searchController = UISearchController(searchResultsController: nil)
    var callListener: ListenerRegistration!

    override func viewWillAppear(_ animated: Bool) {
        loadCalls()
    }

    override func viewWillDisappear(_ animated: Bool) {
        callListener.remove()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setBadges(controller: tabBarController!)
        tableView.tableFooterView = UIView()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredCalls.count
        }
        return allCalls.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                as! CallTableViewCell
        var call: CallClass!
        if searchController.isActive && searchController.searchBar.text != "" {
            call = filteredCalls[indexPath.row]
        } else {
            call = allCalls[indexPath.row]
        }
        cell.generateCellWith(call: call)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            var tempCall: CallClass!
            if searchController.isActive && searchController.searchBar.text != "" {
                tempCall = filteredCalls[indexPath.row]
                filteredCalls.remove(at: indexPath.row)
            } else {
                tempCall = allCalls[indexPath.row]
                allCalls.remove(at: indexPath.row)
            }
            tempCall.deleteCall()
            tableView.reloadData()
        }
    }

    func loadCalls() {
        callListener = reference(.Call).document(FUser.currentId())
                .collection(FUser.currentId()).order(by: kDATE, descending: true)
                .limit(to: 20).addSnapshotListener { snapshot, error in
                    self.allCalls = []
                    guard snapshot != nil else {
                        return
                    }
                    if !snapshot!.isEmpty {
                        let sortedDictionary = dictionaryFromSnapshots(
                                snapshots: snapshot!.documents)
                        for callDictionary in sortedDictionary {
                            let call = CallClass(_dictionary: callDictionary)
                            self.allCalls.append(call)
                        }
                    }
                    self.tableView.reloadData()
                }
    }

    func filteredContentForSearchText(searchText: String, scope: String = "All") {
        filteredCalls = allCalls.filter { (call: CallClass) -> Bool in
            var callerName: String!
            if call.callerId == FUser.currentId() {
                callerName = call.withUserFullName
            } else {
                callerName = call.callerFullName
            }
            return callerName.lowercased().contains(searchText.lowercased())
        }
        tableView.reloadData()
    }

    func updateSearchResults(for searchController: UISearchController) {
        filteredContentForSearchText(searchText: searchController.searchBar.text!)
    }
}
