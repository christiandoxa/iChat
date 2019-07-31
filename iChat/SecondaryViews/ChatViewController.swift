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
        UINavigationControllerDelegate, IQAudioRecorderViewControllerDelegate {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let legitTypes = [kAUDIO, kVIDEO, kTEXT, kLOCATION, kPICTURE]
    var typingListener: ListenerRegistration?
    var updatedChatListener: ListenerRegistration?
    var newChatListener: ListenerRegistration?
    var maxMessagesNumber = 0
    var minMessagesNumber = 0
    var loadOld = false
    var loadedMessagesCount = 0
    var typingCounter = 0
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
    var jsqAvatarDictionary: NSMutableDictionary?
    var avatarImageDictionary: NSMutableDictionary?
    var showAvatars = true
    var firstLoad: Bool?
    var outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(
            with: UIColor.jsq_messageBubbleBlue())
    var incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(
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

    override func viewWillAppear(_ animated: Bool) {
        clearRecentCounter(chatRoomId: chatRoomId)
    }

    override func viewWillDisappear(_ animated: Bool) {
        clearRecentCounter(chatRoomId: chatRoomId)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        createTypingObserver()
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"),
                style: .plain, target: self, action: #selector(backAction))]
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        jsqAvatarDictionary = [:]
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
        if cell.textView != nil {
            if data.senderId == FUser.currentId() {
                cell.textView.textColor = .white
            } else {
                cell.textView.textColor = .black
            }
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

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.row]
        var avatar: JSQMessageAvatarImageDataSource
        if let testAvatar = jsqAvatarDictionary!.object(forKey: message.senderId!) {
            avatar = testAvatar as! JSQMessageAvatarImageDataSource
        } else {
            avatar = JSQMessagesAvatarImageFactory.avatarImage(
                    with: UIImage(named: "avatarPlaceholder"), diameter: 70)
        }
        return avatar
    }

    override func didPressAccessoryButton(_ sender: UIButton!) {
        let camera = Camera(delegate_: self)
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { action in
            camera.PresentMultiCamera(target: self, canEdit: false)
        }
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { action in
            camera.PresentPhotoLibrary(target: self, canEdit: false)
        }
        let shareVideo = UIAlertAction(title: "Video Library", style: .default) { action in
            camera.PresentVideoLibrary(target: self, canEdit: false)
        }
        let shareLocation = UIAlertAction(title: "Share Location", style: .default) { action in
            if self.haveAccessToUserLocation() {
                self.sendMessage(text: nil, date: Date(), picture: nil,
                        location: kLOCATION, video: nil, audio: nil)
            }
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
            let audioVC = AudioViewController(delegate_: self)
            audioVC.presentAudioRecorder(target: self)
        }
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        loadMoreMessages(maxNumber: maxMessagesNumber, minNumber: minMessagesNumber)
        collectionView.reloadData()
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let messageDictionary = objectMessages[indexPath.row]
        let messageType = messageDictionary[kTYPE] as! String
        switch messageType {
        case kPICTURE:
            let message = messages[indexPath.row]
            let mediaItem = message.media as! JSQPhotoMediaItem
            let photos = IDMPhoto.photos(withImages: [mediaItem.image!])
            let browser = IDMPhotoBrowser(photos: photos)
            present(browser!, animated: true)
        case kLOCATION:
            let message = messages[indexPath.row]
            let mediaItem = message.media as! JSQLocationMediaItem
            let mapView = UIStoryboard(name: "Main", bundle: nil)
                    .instantiateViewController(withIdentifier: "MapViewController")
                    as! MapViewController
            mapView.location = mediaItem.location
            navigationController?.pushViewController(mapView, animated: true)
        case kVIDEO:
            let message = messages[indexPath.row]
            let mediaItem = message.media as! VideoMessage
            let player = AVPlayer(url: mediaItem.fileURL! as URL)
            let moviePlayer = AVPlayerViewController()
            let session = AVAudioSession.sharedInstance()
            try! session.setCategory(.playAndRecord, mode: .default,
                    options: .defaultToSpeaker)
            moviePlayer.player = player
            present(moviePlayer, animated: true) {
                moviePlayer.player!.play()
            }
        default:
            print("unknown mess type")
        }
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        let senderId = messages[indexPath.row].senderId
        var selectedUser: FUser?
        if senderId == FUser.currentId() {
            selectedUser = FUser.currentUser()
        } else {
            for user in withUsers {
                if user.objectId == senderId {
                    selectedUser = user
                }
            }
        }
        presentUserProfile(forUser: selectedUser!)
    }

    func sendMessage(text: String?, date: Date, picture: UIImage?, location: String?,
                     video: NSURL?, audio: String?) {
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
                    let text = "[\(kPICTURE)]"
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
        if let video = video {
            let videoData = NSData(contentsOfFile: video.path!)
            let dataThumbnail = videoThumbnail(video: video)
                    .jpegData(compressionQuality: 0.3)
            uploadVideo(video: videoData!, chatRoomId: chatRoomId,
                    view: navigationController!.view) { videoLink in
                if videoLink != nil {
                    let text = "[\(kVIDEO)]"
                    outgoingMessage = OutgoingMessages(message: text,
                            video: videoLink!, thumbNail: dataThumbnail! as NSData,
                            senderId: currentUser!.objectId,
                            senderName: currentUser!.fullname, date: date,
                            status: kDELIVERED, type: kVIDEO)
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
        if let audioPath = audio {
            uploadAudio(audioPath: audioPath, chatRoomId: chatRoomId,
                    view: navigationController!.view) { audioLink in
                if audioLink != nil {
                    let text = "[\(kAUDIO)]"
                    outgoingMessage = OutgoingMessages(message: text, audio: audioLink!,
                            senderId: currentUser!.objectId,
                            senderName: currentUser!.fullname, date: date,
                            status: kDELIVERED, type: kAUDIO)
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
        if location != nil {
            let lat: NSNumber = NSNumber(value: appDelegate.coordinates!.latitude)
            let long: NSNumber = NSNumber(value: appDelegate.coordinates!.longitude)
            let text = "[\(kLOCATION)]"
            outgoingMessage = OutgoingMessages(message: text, latitude: lat,
                    longitude: long, senderId: currentUser!.objectId,
                    senderName: currentUser!.fullname, date: date, status: kDELIVERED,
                    type: kLOCATION)
        }
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
        outgoingMessage!.sendMessage(chatRoomId: chatRoomId,
                messageDictionary: outgoingMessage!.messageDictionary,
                membersIds: membersIds, membersToPush: membersToPush)
    }

    func loadMessages() {
        updatedChatListener = reference(.Message).document(FUser.currentId())
                .collection(chatRoomId).addSnapshotListener { snapshot, error in
                    guard snapshot != nil else {
                        return
                    }
                    if !snapshot!.isEmpty {
                        snapshot!.documentChanges.forEach { diff in
                            if diff.type == .modified {
                                self.updateMessage(
                                        messageDictionary: diff.document.data()
                                                as NSDictionary)
                            }
                        }
                    }
                }
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
                    self.getPictureMessages()
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
                                            self.addNewPictureMessageLink(
                                                    link: item[kPICTURE] as! String)
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
                        self.getPictureMessages()
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
            _ = insertInitialLoadMessages(messageDictionary: messageDictionary)
            loadedMessagesCount += 1
        }
        showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }

    func insertInitialLoadMessages(messageDictionary: NSDictionary) -> Bool {
        let incomingMessage = IncomingMessages(collectionView_: collectionView)
        if (messageDictionary[kSENDERID] as! String) != FUser.currentId() {
            OutgoingMessages.updateMessage(withId: messageDictionary[kMESSAGEID]
                    as! String, chatRoomId: chatRoomId, memberIds: membersIds)
        }
        let message = incomingMessage.createMessage(
                messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        if message != nil {
            objectMessages.append(messageDictionary)
            messages.append(message!)
        }
        return isIncoming(messageDictionary: messageDictionary)
    }

    func updateMessage(messageDictionary: NSDictionary) {
        for index in 0..<objectMessages.count {
            let temp = objectMessages[index]
            if messageDictionary[kMESSAGEID] as! String == temp[kMESSAGEID] as! String {
                objectMessages[index] = messageDictionary
                collectionView.reloadData()
            }
        }
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
        clearRecentCounter(chatRoomId: chatRoomId)
        removeListeners()
        navigationController?.popViewController(animated: true)
    }

    @objc func infoButtonPressed() {
        let mediaVC = UIStoryboard.init(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "medView")
                as! PicturesCollectionViewController
        mediaVC.allImageLinks = allPictureMessages
        navigationController?.pushViewController(mediaVC, animated: true)
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

    func presentUserProfile(forUser: FUser) {
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "profileView")
                as! ProfileViewTableViewController
        profileVC.user = forUser
        navigationController?.pushViewController(profileVC, animated: true)
    }

    func createTypingObserver() {
        typingListener = reference(.Typing).document(chatRoomId)
                .addSnapshotListener { snapshot, error in
                    guard snapshot != nil else {
                        return
                    }
                    if snapshot!.exists {
                        for data in snapshot!.data()! {
                            if data.key != FUser.currentId() {
                                let typing = data.value as! Bool
                                self.showTypingIndicator = typing
                                if typing {
                                    self.scrollToBottom(animated: true)
                                }
                            }
                        }
                    } else {
                        reference(.Typing).document(self.chatRoomId).setData([FUser
                                .currentId(): false])
                    }
                }
    }

    func typingCounterStart() {
        typingCounter += 1
        typingCounterSave(typing: true)
        perform(#selector(typingCounterStop), with: nil, afterDelay: 2.0)
    }

    @objc func typingCounterStop() {
        typingCounter -= 1
        if typingCounter == 0 {
            typingCounterSave(typing: false)
        }
    }

    func typingCounterSave(typing: Bool) {
        reference(.Typing).document(chatRoomId).updateData([
            FUser.currentId(): typing
        ])
    }

    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        typingCounterStart()
        return true
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

    func audioRecorderController(_ controller: IQAudioRecorderViewController, didFinishWithAudioAtPath filePath: String) {
        controller.dismiss(animated: true)
        sendMessage(text: nil, date: Date(), picture: nil, location: nil, video: nil,
                audio: filePath)
    }

    func audioRecorderControllerDidCancel(_ controller: IQAudioRecorderViewController) {
        controller.dismiss(animated: true)
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
            self.getAvatarImages()
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

    func getAvatarImages() {
        if showAvatars {
            collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 30, height: 30)
            collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 30, height: 30)
            avatarImageFrom(fUser: FUser.currentUser()!)
            for user in withUsers {
                avatarImageFrom(fUser: user)
            }
        }
    }

    func avatarImageFrom(fUser: FUser) {
        if fUser.avatar != "" {
            dataImageFromString(pictureString: fUser.avatar) { imageData in
                if imageData == nil {
                    return
                }
                if avatarImageDictionary != nil {
                    avatarImageDictionary?.removeObject(forKey: fUser.objectId)
                    avatarImageDictionary?.setObject(imageData!, forKey: fUser.objectId
                            as NSCopying)
                } else {
                    avatarImageDictionary = [fUser.objectId: imageData!]
                }
                createJSQAvatars(avatarDictionary: avatarImageDictionary)
            }
        }
    }

    func createJSQAvatars(avatarDictionary: NSMutableDictionary?) {
        let defaultAvatar = JSQMessagesAvatarImageFactory.avatarImage(
                with: UIImage(named: "avatarPlaceholder"), diameter: 70)
        if avatarDictionary != nil {
            for userId in membersIds {
                if let avatarImageData = avatarDictionary![userId] {
                    let jsqAvatar = JSQMessagesAvatarImageFactory.avatarImage(
                            with: UIImage(data: avatarImageData as! Data),
                            diameter: 70)
                    jsqAvatarDictionary!.setValue(jsqAvatar, forKey: userId)
                } else {
                    jsqAvatarDictionary!.setValue(defaultAvatar, forKey: userId)
                }
            }
            collectionView.reloadData()
        }
    }

    func haveAccessToUserLocation() -> Bool {
        if appDelegate.locationManager != nil {
            return true
        }
        ProgressHUD.showError("Please give access to location in Settings")
        return false
    }

    func addNewPictureMessageLink(link: String) {
        allPictureMessages.append(link)
    }

    func getPictureMessages() {
        allPictureMessages = []
        for message in loadedMessages {
            if message[kTYPE] as! String == kPICTURE {
                allPictureMessages.append(message[kPICTURE] as! String)
            }
        }
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

    func removeListeners() {
        if typingListener != nil {
            typingListener!.remove()
        }
        if newChatListener != nil {
            newChatListener!.remove()
        }
        if updatedChatListener != nil {
            updatedChatListener!.remove()
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
