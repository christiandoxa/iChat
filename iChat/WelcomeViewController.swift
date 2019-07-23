//
//  WelcomeViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 23/07/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {
    @IBOutlet weak var textFieldEmail: UITextField!
    @IBOutlet weak var textFieldPassword: UITextField!
    @IBOutlet weak var textFieldRepeatPassword: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func buttonLoginPressed(_ sender: Any) {
        print("login")
    }

    @IBAction func buttonRegisterPressed(_ sender: Any) {
        print("register")
    }

    @IBAction func backgroundTap(_ sender: Any) {
        print("background")
    }
}
