//
// Created by Christian Doxa Hamasiah on 2019-07-27.
// Copyright (c) 2019 Christian Doxa Hamasiah. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class IncomingMessages {
    var collectionView: JSQMessagesCollectionView

    init(collectionView_: JSQMessagesCollectionView) {
        collectionView = collectionView_
    }

    func createMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage? {
        var message: JSQMessage?
        let type = messageDictionary[kTYPE] as! String
        switch type {
        case kTEXT:
            message = createTextMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        case kPICTURE:
            message = createPictureMessage(messageDictionary: messageDictionary)
        case kVIDEO:
            message = createVideoMessage(messageDictionary: messageDictionary)
        case kAUDIO:
            print("aud")
        case kLOCATION:
            print("loc")
        default:
            print("Unknown message type")
        }
        if message != nil {
            return message
        }
        return nil
    }

    func createTextMessage(messageDictionary: NSDictionary, chatRoomId: String)
                    -> JSQMessage {
        let name = messageDictionary[kSENDERNAME] as? String
        let userId = messageDictionary[kSENDERID] as? String
        var date: Date!
        if let created = messageDictionary[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        } else {
            date = Date()
        }
        let text = messageDictionary[kMESSAGE] as! String
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, text: text)
    }

    func createPictureMessage(messageDictionary: NSDictionary) -> JSQMessage {
        let name = messageDictionary[kSENDERNAME] as? String
        let userId = messageDictionary[kSENDERID] as? String
        var date: Date!
        if let created = messageDictionary[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        } else {
            date = Date()
        }
        let mediaItem = PhotoMediaItem(image: nil)
        mediaItem?.appliesMediaViewMaskAsOutgoing =
                returnOutgoingStatusForUser(senderId: userId!)
        downloadImage(imageUrl: messageDictionary[kPICTURE] as! String) { image in
            if image != nil {
                mediaItem?.image = image!
                self.collectionView.reloadData()
            }
        }
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, media: mediaItem)
    }

    func createVideoMessage(messageDictionary: NSDictionary) -> JSQMessage {
        let name = messageDictionary[kSENDERNAME] as? String
        let userId = messageDictionary[kSENDERID] as? String
        var date: Date!
        if let created = messageDictionary[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        } else {
            date = Date()
        }
        let videoURL = NSURL(fileURLWithPath: messageDictionary[kVIDEO] as! String)
        let mediaItem = VideoMessage(withFileURL: videoURL,
                maskOutgoing: returnOutgoingStatusForUser(senderId: userId!))
        downloadVideo(videoUrl: messageDictionary[kVIDEO] as! String) { isReadyToPlay, fileName in
            let url = NSURL(fileURLWithPath: fileInDocumentsDirectory(
                    fileName: fileName))
            mediaItem.status = kSUCCESS
            mediaItem.fileURL = url
            imageFromData(pictureData: messageDictionary[kPICTURE] as! String) { image in
                if image != nil {
                    mediaItem.image = image
                    self.collectionView.reloadData()
                }
            }
            self.collectionView.reloadData()
        }
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, media: mediaItem)
    }

    func returnOutgoingStatusForUser(senderId: String) -> Bool {
        return senderId == FUser.currentId()
    }
}
