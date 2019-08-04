//
//  NewGroupViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 2019-08-04.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import ProgressHUD

class NewGroupViewController: UIViewController, UICollectionViewDataSource,
        UICollectionViewDelegate, GroupMemberCollectionViewCellDelegate {
    @IBOutlet weak var editAvatarButtonOutlet: UIButton!
    @IBOutlet weak var groupIconImageView: UIImageView!
    @IBOutlet weak var groupSubjectTextField: UITextField!
    @IBOutlet weak var participantsLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var iconTapGesture: UITapGestureRecognizer!
    var memberIds: [String] = []
    var allMembers: [FUser] = []
    var groupIcon: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        groupIconImageView.isUserInteractionEnabled = true
        groupIconImageView.addGestureRecognizer(iconTapGesture)
        updateParticipantsLabel()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allMembers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell",
                for: indexPath) as! GroupMemberCollectionViewCell
        cell.delegate = self
        cell.generateCell(user: allMembers[indexPath.row], indexPath: indexPath)
        return cell
    }

    @objc func createButtonPressed(_ sender: Any) {
        if groupSubjectTextField.text != "" {
            memberIds.append(FUser.currentId())
            let avatarData = UIImage(named: "groupIcon")!.jpegData(
                    compressionQuality: 0.7)!
            var avatar = avatarData.base64EncodedString(
                    options: NSData.Base64EncodingOptions(rawValue: 0))
            if groupIcon != nil {
                let avatarData = groupIcon!.jpegData(
                        compressionQuality: 0.7)!
                avatar = avatarData.base64EncodedString(
                        options: NSData.Base64EncodingOptions(rawValue: 0))
            }
            let groupId = UUID().uuidString
            let group = Group(groupId: groupId, subject: groupSubjectTextField.text!,
                    ownerId: FUser.currentId(), members: memberIds, avatar: avatar)
            group.saveGroup()
            startGroupChat(group: group)
            let chatVC = ChatViewController()
            chatVC.titleName = (group.groupDictionary[kNAME] as! String)
            chatVC.membersIds = (group.groupDictionary[kMEMBERS] as! [String])
            chatVC.membersToPush = (group.groupDictionary[kMEMBERS] as! [String])
            chatVC.chatRoomId = groupId
            chatVC.isGroup = true
            chatVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(chatVC, animated: true)
        } else {
            ProgressHUD.showError("Subject is required")
        }
    }

    @IBAction func groupIconTapped(_ sender: Any) {
        showIconOptions()
    }

    @IBAction func editIconButtonPressed(_ sender: Any) {
        showIconOptions()
    }

    func didClickDeleteButton(indexPath: IndexPath) {
        allMembers.remove(at: indexPath.row)
        memberIds.remove(at: indexPath.row)
        collectionView.reloadData()
        updateParticipantsLabel()
    }

    func showIconOptions() {
        let optionMenu = UIAlertController(title: "Choose group icon", message: nil,
                preferredStyle: .actionSheet)
        let takePhotoAction = UIAlertAction(title: "Take/Choose Photo", style: .default) {
            alert in
            print("camera")
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        if groupIcon != nil {
            let resetAction = UIAlertAction(title: "Reset", style: .default) {
                alert in
                self.groupIcon = nil
                self.groupIconImageView.image = UIImage(named: "cameraItem")
                self.editAvatarButtonOutlet.isHidden = true
            }
            optionMenu.addAction(resetAction)
        }
        optionMenu.addAction(takePhotoAction)
        optionMenu.addAction(cancelAction)
        if UI_USER_INTERFACE_IDIOM() == .pad {
            if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController {
                currentPopoverpresentioncontroller.sourceView = editAvatarButtonOutlet
                currentPopoverpresentioncontroller.sourceRect = editAvatarButtonOutlet
                        .bounds
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                present(optionMenu, animated: true)
            }
        } else {
            present(optionMenu, animated: true)
        }
    }

    func updateParticipantsLabel() {
        participantsLabel.text = "PARTICIPANTS: \(allMembers.count)"
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Create", style: .plain, target: self,
                    action: #selector(createButtonPressed))
        ]
        navigationItem.rightBarButtonItem!.isEnabled = allMembers.count > 0
    }
}
