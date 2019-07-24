//
//  FinishRegistrationViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 24/07/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import ProgressHUD

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
        cleanTextFields()
        dismissKeyboard()
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func doneButtonPressed(_ sender: Any) {
        dismissKeyboard()
        ProgressHUD.show("Registering...")
        if textFieldName.text != "" && textFieldSurname.text != "" && textFieldCountry.text != "" && textFieldCity.text != "" && textFieldPhone.text != "" {
            FUser.registerUserWith(email: email, password: password, firstName: textFieldName.text!, lastName: textFieldSurname.text!) { (error) in
                if error != nil {
                    ProgressHUD.dismiss()
                    ProgressHUD.showError(error!.localizedDescription)
                    return
                }
                self.registerUser()
            }
        } else {
            ProgressHUD.showError("All fields are required!")
        }
    }

    func registerUser() {
        let fullName = textFieldName.text! + " " + textFieldSurname.text!;
        var tempDictionary: Dictionary = [
            kFIRSTNAME: textFieldName.text!,
            kLASTNAME: textFieldSurname.text!,
            kFULLNAME: fullName,
            kCOUNTRY: textFieldCountry.text!,
            kCITY: textFieldCity.text!,
            kPHONE: textFieldPhone.text!
        ] as [String: Any]
        if avatarImage == nil {
            imageFromInitials(firstName: textFieldName.text, lastName: textFieldSurname.text) { avatarInitials in
                let avatarIMG = avatarInitials.jpegData(compressionQuality: 0.7)
                let avatar = avatarIMG?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                tempDictionary[kAVATAR] = avatar
                self.finishRegistration(withValues: tempDictionary)
            }
        } else {
            let avatarData = avatarImage?.jpegData(compressionQuality: 0.7)
            let avatar = avatarData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            tempDictionary[kAVATAR] = avatar
            self.finishRegistration(withValues: tempDictionary)
        }
    }

    func finishRegistration(withValues: [String: Any]) {
        updateCurrentUserInFirestore(withValues: withValues) { error in
            if error != nil {
                DispatchQueue.main.async {
                    ProgressHUD.showError(error!.localizedDescription)
                    print(error!.localizedDescription)
                }
                return
            }
            ProgressHUD.dismiss()
        }
    }

    func dismissKeyboard() {
        self.view.endEditing(false)
    }

    func cleanTextFields() {
        textFieldName.text = ""
        textFieldSurname.text = ""
        textFieldCountry.text = ""
        textFieldCity.text = ""
        textFieldPhone.text = ""
    }
}
