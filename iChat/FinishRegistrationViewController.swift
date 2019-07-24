//
//  FinishRegistrationViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 24/07/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit

class FinishRegistrationViewController: UIViewController {
    @IBOutlet weak var textFieldName: UITextField!
    @IBOutlet weak var textFieldSurname: UITextField!
    @IBOutlet weak var textFieldCountry: UITextField!
    @IBOutlet weak var textFieldCity: UITextField!
    @IBOutlet weak var textFieldPhone: UITextField!
    @IBOutlet weak var imageViewAvatar: UIImageView!

    var email: String!
    var password: String!
    var avatarImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        print(email!, password!)
    }

    @IBAction func cancelButtonPressed(_ sender: Any) {
    }

    @IBAction func doneButtonPressed(_ sender: Any) {
    }
}
