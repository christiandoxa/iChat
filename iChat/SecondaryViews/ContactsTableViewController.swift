//
//  ContactsTableViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 02/08/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import Contacts
import FirebaseFirestore
import ProgressHUD

class ContactsTableViewController: UITableViewController, UISearchResultsUpdating,
        UserTableViewCellDelegate {
    var users: [FUser] = []
    var matchedUsers: [FUser] = []
    var filteredMatchedUsers: [FUser] = []
    var allUsersGrouped = NSDictionary() as! [String: [FUser]]
    var sectionTitleList: [String] = []
    var isGroup = false
    var memberIdsOfGroupChat: [String] = []
    var membersOfGroupChat: [FUser] = []
    let searchController = UISearchController(searchResultsController: nil)
    lazy var contacts: [CNContact] = {
        let contactStore = CNContactStore()
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactThumbnailImageDataKey] as [Any]
        var allContainers: [CNContainer] = []
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }
        var results: [CNContact] = []
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(
                    withIdentifier: container.identifier)
            do {
                let containerResults = try contactStore.unifiedContacts(
                        matching: fetchPredicate, keysToFetch: keysToFetch
                        as! [CNKeyDescriptor])
                results.append(contentsOf: containerResults)
            } catch {
                print("Error fetching containers")
            }
        }
        return results
    }()

    override func viewWillAppear(_ animated: Bool) {
        //to remove empty cell lines
        tableView.tableFooterView = UIView()
        loadUsers()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Contacts"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        setupButtons()
    }

    //MARK: TableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return 1
        } else {
            return self.allUsersGrouped.count
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredMatchedUsers.count
        } else {
            // find section title
            let sectionTitle = self.sectionTitleList[section]
            // find users for given section title
            let users = self.allUsersGrouped[sectionTitle]
            // return count for users
            return users!.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! UserTableViewCell
        var user: FUser
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredMatchedUsers[indexPath.row]
        } else {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            //get all users of the section
            let users = self.allUsersGrouped[sectionTitle]
            user = users![indexPath.row]
        }
        cell.delegate = self
        cell.generateCellWith(fUser: user, indexPath: indexPath)
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return ""
        } else {
            return self.sectionTitleList[section]
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

    //MARK: TableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let sectionTitle = sectionTitleList[indexPath.section]
        let userToChat: FUser
        if searchController.isActive && searchController.searchBar.text != "" {
            userToChat = filteredMatchedUsers[indexPath.row]
        } else {
            let users = allUsersGrouped[sectionTitle]
            userToChat = users![indexPath.row]
        }
        if !isGroup {
            if !checkBlockedStatus(withUser: userToChat) {
                let chatVC = ChatViewController()
                chatVC.titleName = userToChat.fullname
                chatVC.membersIds = [FUser.currentId(), userToChat.objectId]
                chatVC.membersToPush = [FUser.currentId(), userToChat.objectId]
                chatVC.chatRoomId = startPrivateChat(user1: FUser.currentUser()!,
                        user2: userToChat)
                chatVC.isGroup = false
                chatVC.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(chatVC, animated: true)
            } else {
                ProgressHUD.showError("This user is not available for chat")
            }
        } else {
            if let cell = tableView.cellForRow(at: indexPath) {
                if cell.accessoryType == .checkmark {
                    cell.accessoryType = .none
                } else {
                    cell.accessoryType = .checkmark
                }
            }
            let selected = memberIdsOfGroupChat.contains(userToChat.objectId)
            if selected {
                let objectIndex = memberIdsOfGroupChat.firstIndex(of: userToChat.objectId)
                memberIdsOfGroupChat.remove(at: objectIndex!)
                membersOfGroupChat.remove(at: objectIndex!)
            } else {
                memberIdsOfGroupChat.append(userToChat.objectId)
                membersOfGroupChat.append(userToChat)
            }
            navigationItem.rightBarButtonItem?.isEnabled = memberIdsOfGroupChat.count > 0
        }
    }


    @objc func nextButtonPressed() {
        let newGroupVC = UIStoryboard.init(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "newGroupView")
                as! NewGroupViewController
        newGroupVC.memberIds = memberIdsOfGroupChat
        newGroupVC.allMembers = membersOfGroupChat
        navigationController?.pushViewController(newGroupVC, animated: true)
    }

    @objc func searchNearbyButtonPressed() {
        let userVC = UIStoryboard.init(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "usersTableView")
                as! UsersTableViewController
        navigationController?.pushViewController(userVC, animated: true)
    }

    @objc func inviteButtonPressed() {
        let text = "Hey! Let's chat on iChat \(kAPPURL)"
        let objectsToShare: [Any] = [text]
        let activityViewController = UIActivityViewController(
                activityItems: objectsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view
        activityViewController.setValue("Lets Chat on Ichat", forKey: "subject")
        present(activityViewController, animated: true)
    }

    func loadUsers() {
        ProgressHUD.show()
        reference(.User).order(by: kFIRSTNAME, descending: false).getDocuments { snapshot, error in
            guard snapshot != nil else {
                ProgressHUD.dismiss()
                return
            }
            if !snapshot!.isEmpty {
                self.matchedUsers = []
                self.users.removeAll()
                for userDictionary in snapshot!.documents {
                    let userDictionary = userDictionary.data() as NSDictionary
                    let fUser = FUser(_dictionary: userDictionary)
                    if fUser.objectId != FUser.currentId() {
                        self.users.append(fUser)
                    }
                }
                ProgressHUD.dismiss()
                self.tableView.reloadData()
            }
            ProgressHUD.dismiss()
            self.compareUsers()
        }
    }

    func compareUsers() {
        for user in users {
            if user.phoneNumber != "" {
                let contact = searchForContactUsingPhoneNumber(phoneNumber: user.phoneNumber)
                //if we have a match, we add to our array to display them
                if contact.count > 0 {
                    matchedUsers.append(user)
                }
                self.tableView.reloadData()
            }
        }
//        updateInformationLabel()
        self.splitDataInToSection()
    }

    //MARK: Contacts

    func searchForContactUsingPhoneNumber(phoneNumber: String) -> [CNContact] {
        var result: [CNContact] = []
        //go through all contacts
        for contact in self.contacts {
            if !contact.phoneNumbers.isEmpty {
                //get the digits only of the phone number and replace + with 00
                let phoneNumberToCompareAgainst = updatePhoneNumber(phoneNumber: phoneNumber, replacePlusSign: true)
                //go through every number of each contact
                for phoneNumber in contact.phoneNumbers {
                    let fulMobNumVar = phoneNumber.value
                    let countryCode = fulMobNumVar.value(forKey: "countryCode") as? String
                    let phoneNumber = fulMobNumVar.value(forKey: "digits") as? String
                    let contactNumber = removeCountryCode(countryCodeLetters: countryCode!, fullPhoneNumber: phoneNumber!)
                    //compare phoneNumber of contact with given user's phone number
                    if contactNumber == phoneNumberToCompareAgainst {
                        result.append(contact)
                    }
                }
            }
        }
        return result
    }


    func updatePhoneNumber(phoneNumber: String, replacePlusSign: Bool) -> String {
        if replacePlusSign {
            return phoneNumber.replacingOccurrences(of: "+", with: "").components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        } else {
            return phoneNumber.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        }
    }


    func removeCountryCode(countryCodeLetters: String, fullPhoneNumber: String) -> String {
        let countryCode = CountryCode()
        let countryCodeToRemove = countryCode.codeDictionaryShort[countryCodeLetters.uppercased()]
        //remove + from country code
        let updatedCode = updatePhoneNumber(phoneNumber: countryCodeToRemove!, replacePlusSign: true)
        //remove countryCode
        let replacedNUmber = fullPhoneNumber.replacingOccurrences(of: updatedCode, with: "").components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        //        print("Code \(countryCodeLetters)")
        //        print("full number \(fullPhoneNumber)")
        //        print("code to remove \(updatedCode)")
        //        print("clean number is \(replacedNUmber)")
        return replacedNUmber
    }

    fileprivate func splitDataInToSection() {
        // set section title "" at initial
        var sectionTitle: String = ""
        // iterate all records from array
        for i in 0..<self.matchedUsers.count {
            // get current record
            let currentUser = self.matchedUsers[i]
            // find first character from current record
            let firstChar = currentUser.firstname.first!
            // convert first character into string
            let firstCharString = "\(firstChar)"
            // if first character not match with past section title then create new section
            if firstCharString != sectionTitle {
                // set new title for section
                sectionTitle = firstCharString
                // add new section having key as section title and value as empty array of string
                self.allUsersGrouped[sectionTitle] = []
                // append title within section title list
                if !sectionTitleList.contains(sectionTitle) {
                    self.sectionTitleList.append(sectionTitle)
                }
            }
            // add record to the section
            self.allUsersGrouped[firstCharString]?.append(currentUser)
        }
        tableView.reloadData()
    }

    func filteredContentForSearchText(searchText: String, scope: String = "All") {
        filteredMatchedUsers = matchedUsers.filter { (user: FUser) -> Bool in
            user.firstname.lowercased().contains(searchText.lowercased())
        }
        tableView.reloadData()
    }

    func updateSearchResults(for searchController: UISearchController) {
        filteredContentForSearchText(searchText: searchController.searchBar.text!)
    }

    func didTapAvatarImage(indexPath: IndexPath) {
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "profileView")
                as! ProfileViewTableViewController
        var user: FUser!
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredMatchedUsers[indexPath.row]
        } else {
            let sectionTitle = sectionTitleList[indexPath.row]
            let users = allUsersGrouped[sectionTitle]
            user = users![indexPath.row]
        }
        profileVC.user = user
        navigationController?.pushViewController(profileVC, animated: true)
    }

    func setupButtons() {
        if isGroup {
            let nextButton = UIBarButtonItem(title: "Next", style: .plain,
                    target: self, action: #selector(nextButtonPressed))
            navigationItem.rightBarButtonItem = nextButton
            navigationItem.rightBarButtonItems!.first!.isEnabled = false
        } else {
            let inviteButton = UIBarButtonItem(image: UIImage(named: "invite"), style: .plain, target: self, action: #selector(inviteButtonPressed))
            let searchButton = UIBarButtonItem(image: UIImage(named: "nearMe"), style: .plain, target: self, action: #selector(searchNearbyButtonPressed))
            navigationItem.rightBarButtonItems = [inviteButton, searchButton]
        }
    }
}