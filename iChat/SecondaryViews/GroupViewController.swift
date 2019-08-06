//
//  GroupViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 05/08/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import ProgressHUD
import ImagePicker

class GroupViewController: UIViewController, ImagePickerDelegate {
    @IBOutlet weak var cameraButtonOutlet: UIImageView!
    @IBOutlet weak var editButtonOutlet: UIButton!
    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet var iconTapGesture: UITapGestureRecognizer!
    var group: NSDictionary!
    var groupIcon: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        cameraButtonOutlet.isUserInteractionEnabled = true
        cameraButtonOutlet.addGestureRecognizer(iconTapGesture)
        setupUI()
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Invite Users", style: .plain, target: self,
                    action: #selector(inviteUsers))
        ]
    }

    @IBAction func editButtonPressed(_ sender: Any) {
        showIconOptions()
    }

    @IBAction func cameraIconTapped(_ sender: Any) {
        showIconOptions()
    }

    @IBAction func saveButtonPressed(_ sender: Any) {
        var withValues: [String: Any]!
        if groupNameTextField.text != "" {
            withValues = [kNAME: groupNameTextField.text!]
        } else {
            ProgressHUD.showError("Subject is required")
            return
        }
        let avatarData = cameraButtonOutlet.image?.jpegData(compressionQuality: 0.4)
        let avatarString = avatarData?.base64EncodedString(
                options: NSData.Base64EncodingOptions(rawValue: 0))
        withValues = [
            kNAME: groupNameTextField.text!,
            kAVATAR: avatarString!
        ]
        Group.updateGroup(groupId: group[kGROUPID] as! String, withValues: withValues)
        withValues = [
            kWITHUSERFULLNAME: groupNameTextField.text!,
            kAVATAR: avatarString!
        ]
        updateExistingRecentWithNewValues(chatRoomId: group[kGROUPID] as! String,
                members: group[kMEMBERS] as! [String], withValues: withValues)
        navigationController?.popToRootViewController(animated: true)
    }

    @objc func inviteUsers() {
        let userVC = UIStoryboard.init(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "inviteUsersTableView")
                as! InviteUsersTableViewController
        userVC.group = group
        navigationController?.pushViewController(userVC, animated: true)
    }

    func setupUI() {
        title = "Group"
        groupNameTextField.text = (group[kNAME] as! String)
        imageFromData(pictureData: group[kAVATAR] as! String) { avatarImage in
            if avatarImage != nil {
                cameraButtonOutlet.image = avatarImage!.circleMasked
            }
        }
    }

    func showIconOptions() {
        let optionMenu = UIAlertController(title: "Choose group icon", message: nil,
                preferredStyle: .actionSheet)
        let takePhotoAction = UIAlertAction(title: "Take/Choose Photo", style: .default) {
            alert in
            let imagePickerController = ImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.imageLimit = 1
            self.present(imagePickerController, animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        if groupIcon != nil {
            let resetAction = UIAlertAction(title: "Reset", style: .default) {
                alert in
                self.groupIcon = nil
                self.cameraButtonOutlet.image = UIImage(named: "cameraItem")
                self.editButtonOutlet.isHidden = true
            }
            optionMenu.addAction(resetAction)
        }
        optionMenu.addAction(takePhotoAction)
        optionMenu.addAction(cancelAction)
        if UI_USER_INTERFACE_IDIOM() == .pad {
            if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController {
                currentPopoverpresentioncontroller.sourceView = editButtonOutlet
                currentPopoverpresentioncontroller.sourceRect = editButtonOutlet
                        .bounds
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                present(optionMenu, animated: true)
            }
        } else {
            present(optionMenu, animated: true)
        }
    }

    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        dismiss(animated: true)
    }

    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        if images.count > 0 {
            groupIcon = images.first
            cameraButtonOutlet.image = groupIcon?.circleMasked
            editButtonOutlet.isHidden = false
        }
        dismiss(animated: true)
    }

    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        dismiss(animated: true)
    }
}
