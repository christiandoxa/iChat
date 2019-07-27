//
//  ChatViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 27/07/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import ProgressHUD
import IQAudioRecorderController
import IDMPhotoBrowser
import AVFoundation
import AVKit
import FirebaseFirestore

class ChatViewController: JSQMessagesViewController {
    var outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(
            with: UIColor.jsq_messageBubbleBlue())
    var incomingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(
            with: UIColor.jsq_messageBubbleLightGray())

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"),
                style: .plain, target: self, action: #selector(backAction))]
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        senderId = FUser.currentId()
        senderDisplayName = FUser.currentUser()?.firstname
        inputToolbar.contentView.rightBarButtonItem
                .setImage(UIImage(named: "mic"), for: .normal)
        inputToolbar.contentView.rightBarButtonItem
                .setTitle("", for: .normal)
    }

    override func didPressAccessoryButton(_ sender: UIButton!) {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { action in
            print("Camera")
        }
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { action in
            print("Photo Lib")
        }
        let shareVideo = UIAlertAction(title: "Video Library", style: .default) { action in
            print("Video Library")
        }
        let shareLocation = UIAlertAction(title: "Share Location", style: .default) { action in
            print("Share Location")
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
        }
        takePhotoOrVideo.setValue(UIImage(named: "camera"), forKey: "image")
        sharePhoto.setValue(UIImage(named: "picture"), forKey: "image")
        shareVideo.setValue(UIImage(named: "video"), forKey: "image")
        shareLocation.setValue(UIImage(named: "location"), forKey: "image")
        optionMenu.addAction(takePhotoOrVideo)
        optionMenu.addAction(sharePhoto)
        optionMenu.addAction(shareVideo)
        optionMenu.addAction(shareLocation)
        optionMenu.addAction(cancelAction)
        present(optionMenu, animated: true)
    }

    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {

    }

    @objc func backAction() {
        navigationController?.popViewController(animated: true)
    }
}

extension JSQMessagesInputToolbar {
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = window else {
            return
        }
        let anchor = window.safeAreaLayoutGuide.bottomAnchor
        bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: anchor, multiplier: 1.0).isActive = true
    }
}
