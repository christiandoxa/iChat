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
        senderId = FUser.currentId()
        senderDisplayName = FUser.currentUser()?.firstname
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
