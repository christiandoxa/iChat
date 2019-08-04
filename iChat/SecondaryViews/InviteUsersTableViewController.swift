//
//  InviteUsersTableViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 05/08/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import ProgressHUD
import FirebaseFirestore

class InviteUsersTableViewController: UITableViewController, UserTableViewCellDelegate {
    @IBOutlet weak var headerView: UIView!
    var allUsers: [FUser] = []
    var filteredUsers: [FUser] = []
    var allUsersGrouped = NSDictionary() as! [String: [FUser]]
    var sectionTitleList: [String] = []
    var newMemberIds: [String] = []
    var currentMemberIds: [String] = []
    var group: NSDictionary!

    override func viewWillAppear(_ animated: Bool) {
        loadUsers(filter: kCITY)
    }

    override func viewWillDisappear(_ animated: Bool) {
        ProgressHUD.dismiss()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Users"
        tableView.tableFooterView = UIView()
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Done", style: .done, target: self,
                    action: #selector(doneButtonPressed))
        ]
        navigationItem.rightBarButtonItem?.isEnabled = false
        currentMemberIds = group[kMEMBERS] as! [String]
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return allUsersGrouped.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionTitle = sectionTitleList[section]
        return allUsersGrouped[sectionTitle]!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
        let sectionTitle = self.sectionTitleList[indexPath.section]
        let users = self.allUsersGrouped[sectionTitle]
        cell.generateCellWith(fUser: users![indexPath.row], indexPath: indexPath)
        cell.delegate = self
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitleList[section]
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionTitleList
    }

    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let sectionTitle = sectionTitleList[indexPath.section]
        let users = allUsersGrouped[sectionTitle]
        let selectedUser = users![indexPath.row]
        if currentMemberIds.contains(selectedUser.objectId) {
            ProgressHUD.showError("Already in the group")
            return
        } else {
            if let cell = tableView.cellForRow(at: indexPath) {
                if cell.accessoryType == .checkmark {
                    cell.accessoryType = .none
                } else {
                    cell.accessoryType = .checkmark
                }
            }
        }
        let selected = newMemberIds.contains(selectedUser.objectId)
        if selected {
            let objectIndex = newMemberIds.firstIndex(of: selectedUser.objectId)
            newMemberIds.remove(at: objectIndex!)
        } else {
            newMemberIds.append(selectedUser.objectId)
        }
        navigationItem.rightBarButtonItem?.isEnabled = newMemberIds.count > 0
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

    @objc func doneButtonPressed() {
    }

    func didTapAvatarImage(indexPath: IndexPath) {
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "profileView")
                as! ProfileViewTableViewController
        let sectionTitle = self.sectionTitleList[indexPath.section]
        let users = self.allUsersGrouped[sectionTitle]
        profileVC.user = users![indexPath.row]
        navigationController?.pushViewController(profileVC, animated: true)
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
                if !sectionTitleList.contains(sectionTitle) {
                    self.sectionTitleList.append(sectionTitle)
                }
            }
            self.allUsersGrouped[firstCharString]?.append(currentUser)
        }
    }
}
