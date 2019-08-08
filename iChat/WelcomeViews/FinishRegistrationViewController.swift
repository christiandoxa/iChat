//
//  FinishRegistrationViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 24/07/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import ProgressHUD
import ImagePicker

class FinishRegistrationViewController: UIViewController, ImagePickerDelegate {
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
        imageViewAvatar.isUserInteractionEnabled = true
    }

    @IBAction func avatarImageTap(_ sender: Any) {
        let imagePickerController = ImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.imageLimit = 1
        present(imagePickerController, animated: true)
        dismissKeyboard()
    }

    @IBAction func cancelButtonPressed(_ sender: Any) {
        cleanTextFields()
        dismissKeyboard()
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func doneButtonPressed(_ sender: Any) {
        dismissKeyboard()
        ProgressHUD.show("Registering...")
        if textFieldName.text != "" && textFieldSurname.text != "" &&
                   textFieldCountry.text != "" && textFieldCity.text != "" &&
                   textFieldPhone.text != "" {
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
            let avatarData = avatarImage?.jpegData(compressionQuality: 0.5)
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
            self.goToApp()
        }
    }

    func goToApp() {
        cleanTextFields()
        dismissKeyboard()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID: FUser.currentId()])
        let mainView = UIStoryboard.init(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "mainApplication")
                as! UITabBarController
        self.present(mainView, animated: true)
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

    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        dismiss(animated: true)
    }

    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        if images.count > 0 {
            avatarImage = images.first
            imageViewAvatar.image = avatarImage?.circleMasked
        }
        dismiss(animated: true)
    }

    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        dismiss(animated: true)
    }
}
