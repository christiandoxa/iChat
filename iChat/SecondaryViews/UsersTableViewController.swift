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

class UsersTableViewController: UITableViewController, UISearchResultsUpdating, UserTableViewCellDelegate {
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var filterSegmentedControl: UISegmentedControl!
    var allUsers: [FUser] = []
    var filteredUsers: [FUser] = []
    var allUsersGrouped = NSDictionary() as! [String: [FUser]]
    var sectionTitleList: [String] = []
    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Users"
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        loadUsers(filter: kCITY)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return 1
        } else {
            return allUsersGrouped.count
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredUsers.count
        } else {
            let sectionTitle = self.sectionTitleList[section]
            let users = self.allUsersGrouped[sectionTitle]
            return users!.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
        var user: FUser
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUsers[indexPath.row]
        } else {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUsersGrouped[sectionTitle]
            user = users![indexPath.row]
        }
        cell.generateCellWith(fUser: user, indexPath: indexPath)
        cell.delegate = self
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return nil
        } else {
            return sectionTitleList[section]
        }
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return nil
        } else {
            return self.sectionTitleList
        }
    }

    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var user: FUser
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUsers[indexPath.row]
        } else {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUsersGrouped[sectionTitle]
            user = users![indexPath.row]
        }
        _ = startPrivateChat(user1: FUser.currentUser()!, user2: user)
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
                self.splitDataIntoSection()
                self.tableView.reloadData()
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

    fileprivate func splitDataIntoSection() {
        var sectionTitle: String = ""
        for i in 0..<self.allUsers.count {
            let currentUser = self.allUsers[i]
            let firstChar = currentUser.firstname.first
            let firstCharString = String(firstChar!)
            if firstCharString != sectionTitle {
                sectionTitle = firstCharString
                self.allUsersGrouped[sectionTitle] = []
                self.sectionTitleList.append(sectionTitle)
            }
            self.allUsersGrouped[firstCharString]?.append(currentUser)
        }
    }

    func didTapAvatarImage(indexPath: IndexPath) {
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "profileView")
                as! ProfileViewTableViewController
        var user: FUser
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUsers[indexPath.row]
        } else {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUsersGrouped[sectionTitle]
            user = users![indexPath.row]
        }
        profileVC.user = user
        navigationController?.pushViewController(profileVC, animated: true)
    }
}
