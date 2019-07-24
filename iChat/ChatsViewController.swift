//
//  ChatsViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 25/07/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit

class ChatsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func createNewChatButtonPressed(_ sender: Any) {
        let userVC = UIStoryboard.init(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "usersTableView")
                as! UsersTableViewController
        self.navigationController?.pushViewController(userVC, animated: true)
    }
}
