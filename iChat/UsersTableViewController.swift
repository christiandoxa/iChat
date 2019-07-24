//
//  UsersTableViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 2019-07-24.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import FirebaseFirestore
import ProgressHUD

class UsersTableViewController: UITableViewController, UISearchResultsUpdating {
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var filterSegmentedControl: UISegmentedControl!
    var allUsers: [FUser] = []
    var filteredUsers: [FUser] = []
    var allUsersGrouped = NSDictionary() as! [String: [FUser]]
    var sectionTitleList: [String] = []
    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        loadUsers(filter: kCITY)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allUsers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
        cell.generateCellWith(fUser: allUsers[indexPath.row], indexPath: indexPath)
        return cell
    }

    func loadUsers(filter: String) {
        ProgressHUD.show()
        var query: Query!
        switch filter {
        case kCITY:
            query = reference(.User).whereField(kCITY, isEqualTo: FUser.currentUser()!.city)
                    .order(by: kFIRSTNAME, descending: false)
        case kCOUNTRY:
            query = reference(.User).whereField(kCOUNTRY, isEqualTo: FUser.currentUser()!.country)
                    .order(by: kFIRSTNAME, descending: false)
        default:
            query = reference(.User).order(by: kFIRSTNAME, descending: false)
        }
        query.getDocuments { snapshot, error in
            self.allUsers = []
            self.sectionTitleList = []
            self.allUsersGrouped = [:]
            if error != nil {
                print(error!.localizedDescription)
                ProgressHUD.dismiss()
                self.tableView.reloadData()
                return
            }
            guard snapshot != nil else {
                ProgressHUD.dismiss()
                return
            }
            if !snapshot!.isEmpty {
                for userDictionary in snapshot!.documents {
                    let userDictionary = userDictionary.data() as NSDictionary
                    let fUser = FUser(_dictionary: userDictionary)
                    if fUser.objectId != FUser.currentId() {
                        self.allUsers.append(fUser)
                    }
                }
            }
            self.tableView.reloadData()
            ProgressHUD.dismiss()
        }
    }

    @IBAction func filterSegmentValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            loadUsers(filter: kCITY)
        case 1:
            loadUsers(filter: kCOUNTRY)
        case 2:
            loadUsers(filter: "")
        default:
            return
        }
    }

    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredUsers = allUsers.filter { (user: FUser) -> Bool in
            user.firstname.lowercased().contains(searchText.lowercased())
        }
        tableView.reloadData()
    }

    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}
