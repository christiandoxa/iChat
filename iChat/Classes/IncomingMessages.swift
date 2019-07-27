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
            print("pict")
        case kVIDEO:
            print("vid")
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
}
