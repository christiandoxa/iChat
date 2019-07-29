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

class ChatViewController: JSQMessagesViewController, UIImagePickerControllerDelegate,
        UINavigationControllerDelegate {
    let legitTypes = [kAUDIO, kVIDEO, kTEXT, kLOCATION, kPICTURE]
    var typingListener: ListenerRegistration?
    var updatedChatListener: ListenerRegistration?
    var newChatListener: ListenerRegistration?
    var maxMessagesNumber = 0
    var minMessagesNumber = 0
    var loadOld = false
    var loadedMessagesCount = 0
    var chatRoomId: String!
    var membersIds: [String]!
    var membersToPush: [String]!
    var titleName: String!
    var isGroup: Bool?
    var group: NSDictionary?
    var withUsers: [FUser] = []
    var messages: [JSQMessage] = []
    var objectMessages: [NSDictionary] = []
    var loadedMessages: [NSDictionary] = []
    var allPictureMessages: [String] = []
    var initialLoadComplete = false
    var outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(
            with: UIColor.jsq_messageBubbleBlue())
    var incomingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(
            with: UIColor.jsq_messageBubbleLightGray())
    let leftBarButtonView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        return view
    }()
    let avatarButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 10, width: 25, height: 25))
        return button
    }()
    let titleLabel: UILabel = {
        let title = UILabel(frame: CGRect(x: 30, y: 10, width: 140, height: 15))
        title.textAlignment = .left
        title.font = UIFont(name: title.font.fontName, size: 14)
        return title
    }()
    let subtitleLabel: UILabel = {
        let subTitle = UILabel(frame: CGRect(x: 30, y: 25, width: 140, height: 15))
        subTitle.textAlignment = .left
        subTitle.font = UIFont(name: subTitle.font.fontName, size: 10)
        return subTitle
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"),
                style: .plain, target: self, action: #selector(backAction))]
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        setCustomTitle()
        loadMessages()
        senderId = FUser.currentId()
        senderDisplayName = FUser.currentUser()?.firstname
        inputToolbar.contentView.rightBarButtonItem
                .setImage(UIImage(named: "mic"), for: .normal)
        inputToolbar.contentView.rightBarButtonItem
                .setTitle("", for: .normal)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let data = messages[indexPath.row]
        if data.senderId == FUser.currentId() {
            cell.textView.textColor = .white
        } else {
            cell.textView.textColor = .black
        }
        return cell
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData {
        return messages[indexPath.row]
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let data = messages[indexPath.row]
        if data.senderId == FUser.currentId() {
            return outgoingBubble
        } else {
            return incomingBubble
        }
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        if indexPath.item % 3 == 0 {
            let message = messages[indexPath.row]
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }
        return nil
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = objectMessages[indexPath.row]
        let status: NSAttributedString!
        let attributedStringColor = [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        switch message[kSTATUS] as! String {
        case kDELIVERED:
            status = NSAttributedString(string: kDELIVERED)
        case kREAD:
            let statusText = "Read" + " " + readTimeFrom(dateString: message[kREADDATE] as! String)
            status = NSAttributedString(string: statusText, attributes: attributedStringColor)
        default:
            status = NSAttributedString(string: "✔︎")
        }
        if indexPath.row == messages.count - 1 {
            return status
        } else {
            return NSAttributedString(string: "")
        }
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        let data = messages[indexPath.row]
        if data.senderId == FUser.currentId() {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0.0
        }
    }

    override func didPressAccessoryButton(_ sender: UIButton!) {
        let camera = Camera(delegate_: self)
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { action in
            print("Camera")
        }
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { action in
            camera.PresentPhotoLibrary(target: self, canEdit: true)
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

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        loadMoreMessages(maxNumber: maxMessagesNumber, minNumber: minMessagesNumber)
        collectionView.reloadData()
    }

    func sendMessage(text: String?, date: Date, picture: UIImage?, location: String?, video: NSURL?, audio: String?) {
        var outgoingMessage: OutgoingMessages?
        let currentUser = FUser.currentUser()
        if let text = text {
            outgoingMessage = OutgoingMessages(message: text,
                    senderId: currentUser!.objectId, senderName: currentUser!.firstname,
                    date: date, status: kDELIVERED, type: kTEXT)
        }
        if let pic = picture {
            uploadImage(image: pic, chatRoomId: chatRoomId,
                    view: self.navigationController!.view) { imageLink in
                if imageLink != nil {
                    let text = kPICTURE
                    outgoingMessage = OutgoingMessages(message: text,
                            pictureLink: imageLink!, senderId: currentUser!.objectId,
                            senderName: currentUser!.fullname, date: date,
                            status: kDELIVERED, type: kPICTURE)
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    outgoingMessage?.sendMessage(chatRoomId: self.chatRoomId,
                            messageDictionary: outgoingMessage!.messageDictionary,
                            membersIds: self.membersIds,
                            membersToPush: self.membersToPush)
                }
            }
            return
        }
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
        outgoingMessage!.sendMessage(chatRoomId: chatRoomId,
                messageDictionary: outgoingMessage!.messageDictionary,
                membersIds: membersIds, membersToPush: membersToPush)
    }

    func loadMessages() {
        // get last eleven messages
        reference(.Message).document(FUser.currentId()).collection(chatRoomId)
                .order(by: kDATE, descending: true).limit(to: 11)
                .getDocuments { snapshot, error in
                    guard snapshot != nil else {
                        self.initialLoadComplete = true
                        return
                    }
                    let sorted = ((dictionaryFromSnapshots(snapshots: snapshot!
                            .documents)) as NSArray)
                            .sortedArray(using: [NSSortDescriptor(key: kDATE,
                            ascending: true)]) as! [NSDictionary]
                    self.loadedMessages = self.removeBadMessages(allMessages: sorted)
                    self.insertMessages()
                    self.finishReceivingMessage(animated: true)
                    self.initialLoadComplete = true
                    self.getOldMessagesInBackground()
                    self.listenForNewChats()
                }
    }

    func listenForNewChats() {
        var lastMessageDate = "0"
        if loadedMessages.count > 0 {
            lastMessageDate = loadedMessages.last![kDATE] as! String
        }
        newChatListener = reference(.Message).document(FUser.currentId())
                .collection(chatRoomId).whereField(kDATE, isGreaterThan: lastMessageDate)
                .addSnapshotListener { snapshot, error in
                    guard snapshot != nil else {
                        return
                    }
                    if !snapshot!.isEmpty {
                        for diff in snapshot!.documentChanges {
                            if diff.type == .added {
                                let item = diff.document.data() as NSDictionary
                                if let type = item[kTYPE] {
                                    if self.legitTypes.contains(type as! String) {
                                        if type as! String == kPICTURE {

                                        }
                                        if self.insertInitialLoadMessages(messageDictionary: item) {
                                            JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                                        }
                                        self.finishReceivingMessage()
                                    }
                                }
                            }
                        }
                    }
                }
    }

    func getOldMessagesInBackground() {
        if loadedMessages.count > 10 {
            let lastMessageDate = loadedMessages.first?[kDATE] as! String
            reference(.Message).document(FUser.currentId()).collection(chatRoomId)
                    .whereField(kDATE, isLessThan: lastMessageDate)
                    .getDocuments { snapshot, error in
                        guard snapshot != nil else {
                            return
                        }
                        let sorted = ((dictionaryFromSnapshots(snapshots: snapshot!
                                .documents)) as NSArray)
                                .sortedArray(using: [NSSortDescriptor(key: kDATE,
                                ascending: true)]) as! [NSDictionary]
                        self.loadedMessages = self.removeBadMessages(
                                allMessages: sorted) + self.loadedMessages
                        self.maxMessagesNumber = self.loadedMessages.count - self.loadedMessagesCount - 1
                        self.minMessagesNumber = self.maxMessagesNumber - kNUMBEROFMESSAGES
                    }
        }
    }

    func insertMessages() {
        maxMessagesNumber = loadedMessages.count - loadedMessagesCount
        minMessagesNumber = maxMessagesNumber - kNUMBEROFMESSAGES
        if minMessagesNumber < 0 {
            minMessagesNumber = 0
        }
        for i in minMessagesNumber..<maxMessagesNumber {
            let messageDictionary = loadedMessages[i]
            insertInitialLoadMessages(messageDictionary: messageDictionary)
            loadedMessagesCount += 1
        }
        showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }

    func insertInitialLoadMessages(messageDictionary: NSDictionary) -> Bool {
        let incomingMessage = IncomingMessages(collectionView_: collectionView)
        if (messageDictionary[kSENDERID] as! String) != FUser.currentId() {
            //update message status

        }
        let message = incomingMessage.createMessage(
                messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        if message != nil {
            objectMessages.append(messageDictionary)
            messages.append(message!)
        }
        return isIncoming(messageDictionary: messageDictionary)
    }

    func loadMoreMessages(maxNumber: Int, minNumber: Int) {
        if loadOld {
            maxMessagesNumber = minNumber - 1
            minMessagesNumber = maxMessagesNumber - kNUMBEROFMESSAGES
        }
        if minMessagesNumber < 0 {
            minMessagesNumber = 0
        }
        for i in (minMessagesNumber...maxMessagesNumber).reversed() {
            let messageDictionary = loadedMessages[i]
            insertNewMessage(messageDictionary: messageDictionary)
            loadedMessagesCount += 1
        }
        loadOld = true
        showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }

    func insertNewMessage(messageDictionary: NSDictionary) {
        let incomingMessage = IncomingMessages(collectionView_: collectionView)
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        objectMessages.insert(messageDictionary, at: 0)
        messages.insert(message!, at: 0)
    }

    @objc func backAction() {
        navigationController?.popViewController(animated: true)
    }

    @objc func infoButtonPressed() {
        print("show image message")
    }

    @objc func showGroup() {
        print("show group")
    }

    @objc func showUserProfile() {
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "profileView")
                as! ProfileViewTableViewController
        profileVC.user = withUsers.first!
        navigationController?.pushViewController(profileVC, animated: true)
    }

    override func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            updateSendButton(isSend: true)
        } else {
            updateSendButton(isSend: false)
        }
    }

    func updateSendButton(isSend: Bool) {
        if isSend {
            inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "send"), for: .normal)
        } else {
            inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        }
    }

    func setCustomTitle() {
        leftBarButtonView.addSubview(avatarButton)
        leftBarButtonView.addSubview(titleLabel)
        leftBarButtonView.addSubview(subtitleLabel)
        let infoButton = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(infoButtonPressed))
        navigationItem.rightBarButtonItem = infoButton
        let leftBarButtonItem = UIBarButtonItem(customView: leftBarButtonView)
        navigationItem.leftBarButtonItems?.append(leftBarButtonItem)
        if isGroup! {
            avatarButton.addTarget(self, action: #selector(showGroup), for: .touchUpInside)
        } else {
            avatarButton.addTarget(self, action: #selector(showUserProfile), for: .touchUpInside)
        }
        getUsersFromFirestore(withIds: membersIds) { withUsers in
            self.withUsers = withUsers
            if !self.isGroup! {
                self.setUIForSingleChat()
            }
        }
    }

    func setUIForSingleChat() {
        let withUser = withUsers.first!
        imageFromData(pictureData: withUser.avatar) { image in
            if image != nil {
                avatarButton.setImage(image!.circleMasked, for: .normal)
            }
        }
        titleLabel.text = withUser.fullname
        if withUser.isOnline {
            subtitleLabel.text = "Online"
        } else {
            subtitleLabel.text = "Offline"
        }
        avatarButton.addTarget(self, action: #selector(showUserProfile), for: .touchUpInside)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo
    info: [UIImagePickerController.InfoKey: Any]) {
        let video = info[.mediaURL] as? NSURL
        let picture = info[.originalImage] as? UIImage
        sendMessage(text: nil, date: Date(), picture: picture, location: nil,
                video: video, audio: nil)
        picker.dismiss(animated: true)
    }

    func readTimeFrom(dateString: String) -> String {
        let date = dateFormatter().date(from: dateString)
        let currentDateFormat = dateFormatter()
        currentDateFormat.dateFormat = "HH:mm"
        return currentDateFormat.string(from: date!)
    }

    func removeBadMessages(allMessages: [NSDictionary]) -> [NSDictionary] {
        var tempMessages = allMessages
        for message in tempMessages {
            if message[kTYPE] != nil {
                if !legitTypes.contains(message[kTYPE] as! String) {
                    tempMessages.remove(at: tempMessages.firstIndex(of: message)!)
                }
            } else {
                tempMessages.remove(at: tempMessages.firstIndex(of: message)!)
            }
        }
        return tempMessages
    }

    func isIncoming(messageDictionary: NSDictionary) -> Bool {
        if FUser.currentId() == messageDictionary[kSENDERID] as! String {
            return false
        } else {
            return true
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
