//
//  ChatsViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 25/07/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ChatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var recentChats: [NSDictionary] = []
    var filteredChats: [NSDictionary] = []
    var recentListener: ListenerRegistration!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        loadRecentChats()
    }

    @IBAction func createNewChatButtonPressed(_ sender: Any) {
        let userVC = UIStoryboard.init(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "usersTableView")
                as! UsersTableViewController
        self.navigationController?.pushViewController(userVC, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentChats.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                as! RecentChatsTableViewCell
        let recent = recentChats[indexPath.row]
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
}
