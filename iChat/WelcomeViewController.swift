//
//  WelcomeViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 23/07/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import ProgressHUD

class WelcomeViewController: UIViewController {
    @IBOutlet weak var textFieldEmail: UITextField!
    @IBOutlet weak var textFieldPassword: UITextField!
    @IBOutlet weak var textFieldRepeatPassword: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func buttonLoginPressed(_ sender: Any) {
        dismissKeyboard()
        if (textFieldEmail.text != "" && textFieldPassword.text != "") {
            loginUser()
        } else {
            ProgressHUD.showError("Email and Password is missing")
        }
    }

    @IBAction func buttonRegisterPressed(_ sender: Any) {
        dismissKeyboard()
        if (textFieldEmail.text != "" && textFieldPassword.text != "" && textFieldRepeatPassword.text != "") {
            if textFieldPassword.text == textFieldRepeatPassword.text {
                registerUser()
            } else {
                ProgressHUD.showError("Passwords don't match!")
            }
        } else {
            ProgressHUD.showError("All fields are required!")
        }
    }

    @IBAction func backgroundTap(_ sender: Any) {
        dismissKeyboard()
    }

    func loginUser() {
        ProgressHUD.show("Login...")
        FUser.loginUserWith(email: textFieldEmail.text!, password: textFieldPassword.text!) { (error) in
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                return
            }
            self.goToApp()
        }
    }

    func registerUser() {
        performSegue(withIdentifier: "welcomeToFinishReg", sender: self)
        cleanTextFields()
        dismissKeyboard()
    }

    func dismissKeyboard() {
        self.view.endEditing(false)
    }

    func cleanTextFields() {
        textFieldEmail.text = ""
        textFieldPassword.text = ""
        textFieldRepeatPassword.text = ""
    }

    func goToApp() {
        ProgressHUD.dismiss()
        cleanTextFields()
        dismissKeyboard()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID: FUser.currentId()])
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        self.present(mainView, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "welcomeToFinishReg" {
            let vc = segue.destination as! FinishRegistrationViewController
            vc.email = textFieldEmail.text!
            vc.password = textFieldPassword.text!
        }
    }
}
