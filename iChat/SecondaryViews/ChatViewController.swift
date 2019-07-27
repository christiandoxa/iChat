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
    var chatRoomId: String!
    var membersIds: [String]!
    var membersToPush: [String]!
    var titleName: String!
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
        if UI_USER_INTERFACE_IDIOM() == .pad {
            if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController {
                currentPopoverpresentioncontroller.sourceView = inputToolbar.contentView
                        .leftBarButtonItem
                currentPopoverpresentioncontroller.sourceRect = inputToolbar.contentView
                        .leftBarButtonItem.bounds
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                present(optionMenu, animated: true)
            }
        } else {
            present(optionMenu, animated: true)
        }
    }

    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        if text != "" {
            sendMessage(text: text, date: date, picture: nil, location: nil, video: nil, audio: nil)
            updateSendButton(isSend: false)
        } else {
            print("audio message")
        }
    }

    func sendMessage(text: String?, date: Date, picture: UIImage?, location: String?, video: NSURL?, audio: String?) {
        var outgoingMessage: OutgoingMessages?
        let currentUser = FUser.currentUser()
        if let text = text {
            outgoingMessage = OutgoingMessages(message: text,
                    senderId: currentUser!.objectId, senderName: currentUser!.firstname,
                    date: date, status: kDELIVERED, type: kTEXT)
        }
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
        outgoingMessage!.sendMessage(chatRoomId: chatRoomId,
                messageDictionary: outgoingMessage!.messageDictionary,
                membersIds: membersIds, membersToPush: membersToPush)
    }

    @objc func backAction() {
        navigationController?.popViewController(animated: true)
    }

    func updateSendButton(isSend: Bool) {
        if isSend {
            inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "send"), for: .normal)
        } else {
            inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        }
    }

    override func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            updateSendButton(isSend: true)
        } else {
            updateSendButton(isSend: false)
        }
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
