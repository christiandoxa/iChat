//
//  ChatsViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 25/07/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ChatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
        RecentChatsTableViewCellDelegate, UISearchResultsUpdating {
    @IBOutlet weak var tableView: UITableView!
    var recentChats: [NSDictionary] = []
    var filteredChats: [NSDictionary] = []
    var recentListener: ListenerRegistration!
    let searchController = UISearchController(searchResultsController: nil)

    override func viewWillAppear(_ animated: Bool) {
        loadRecentChats()
        tableView.tableFooterView = UIView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        recentListener.remove()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        setTableViewHeader()
    }

    @IBAction func createNewChatButtonPressed(_ sender: Any) {
        let userVC = UIStoryboard.init(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "usersTableView")
                as! UsersTableViewController
        self.navigationController?.pushViewController(userVC, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredChats.count
        } else {
            return recentChats.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                as! RecentChatsTableViewCell
        cell.delegate = self
        var recent: NSDictionary
        if searchController.isActive && searchController.searchBar.text != "" {
            recent = filteredChats[indexPath.row]
        } else {
            recent = recentChats[indexPath.row]
        }
        cell.generateCell(recentChat: recent, indexPath: indexPath)
        return cell
    }

    func loadRecentChats() {
        recentListener = reference(.Recent).whereField(kUSERID, isEqualTo: FUser.currentId())
                .addSnapshotListener { snapshot, error in
                    guard snapshot != nil else {
                        return
                    }
                    self.recentChats = []
                    if !snapshot!.isEmpty {
                        let sorted = ((dictionaryFromSnapshots(snapshots: snapshot!.documents)) as NSArray)
                                .sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)])
                                as! [NSDictionary]
                        for recent in sorted {
                            if recent[kLASTMESSAGE] as! String != "" && recent[kCHATROOMID] != nil
                                       && recent[kRECENTID] != nil {
                                self.recentChats.append(recent)
                            }
                        }
                        self.tableView.reloadData()
                    }
                }
    }

    func setTableViewHeader() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 45))
        let buttonView = UIView(frame: CGRect(x: 0, y: 2.5, width: tableView.frame.width, height: 35))
        let groupButton = UIButton(frame: CGRect(x: tableView.frame.width - 110, y: 10, width: 100, height: 20))
        groupButton.addTarget(self, action: #selector(groupButtonPressed), for: .touchUpInside)
        groupButton.setTitle("New Group", for: .normal)
        let buttonColor = #colorLiteral(red: 0.003353859764, green: 0.4768753648, blue: 0.9985178113, alpha: 1)
        groupButton.setTitleColor(buttonColor, for: .normal)
        let lineView = UIView(frame: CGRect(x: 0, y: headerView.frame.height - 1, width: tableView.frame.width, height: 1))
        lineView.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        buttonView.addSubview(groupButton)
        headerView.addSubview(buttonView)
        headerView.addSubview(lineView)
        tableView.tableHeaderView = headerView
    }

    @objc func groupButtonPressed() {
        print("group")
    }

    func didTapAvatarImage(indexPath: IndexPath) {
        var recentChat: NSDictionary
        if searchController.isActive && searchController.searchBar.text != "" {
            recentChat = filteredChats[indexPath.row]
        } else {
            recentChat = recentChats[indexPath.row]
        }
        if recentChat[kTYPE] as! String == kPRIVATE {
            reference(.User).document(recentChat[kWITHUSERUSERID] as! String).getDocument { snapshot, error in
                guard snapshot != nil else {
                    return
                }
                if snapshot!.exists {
                    let userDictionary = snapshot!.data()! as NSDictionary
                    let tempUser = FUser(_dictionary: userDictionary)
                    self.showUserProfile(user: tempUser)
                }
            }
        }
    }

    func showUserProfile(user: FUser) {
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "profileView")
                as! ProfileViewTableViewController
        profileVC.user = user
        navigationController?.pushViewController(profileVC, animated: true)
    }

    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredChats = recentChats.filter { recentChat -> Bool in
            (recentChat[kWITHUSERFULLNAME] as! String).lowercased()
                    .contains(searchText.lowercased())
        }
        tableView.reloadData()
    }

    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}
