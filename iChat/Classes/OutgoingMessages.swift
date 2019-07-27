//
// Created by Christian Doxa Hamasiah on 2019-07-27.
// Copyright (c) 2019 Christian Doxa Hamasiah. All rights reserved.
//

import Foundation

class OutgoingMessages {
    let messageDictionary: NSMutableDictionary

    init(message: String, senderId: String, senderName: String, date: Date,
         status: String, type: String) {
        messageDictionary = NSMutableDictionary(
                objects: [
                    message,
                    senderId,
                    senderName,
                    dateFormatter().string(from: date),
                    status,
                    type
                ],
                forKeys: [
                    kMESSAGE as NSCopying,
                    kSENDERID as NSCopying,
                    kSENDERNAME as NSCopying,
                    kDATE as NSCopying,
                    kSTATUS as NSCopying,
                    kTYPE as NSCopying
                ])
    }

    func sendMessage(chatRoomId: String, messageDictionary: NSMutableDictionary,
                     membersIds: [String], membersToPush: [String]) {
        let messageId = UUID().uuidString
        messageDictionary[kMESSAGEID] = messageId
        for memberId in membersIds {
            reference(.Message).document(memberId).collection(chatRoomId)
                    .document(messageId).setData(messageDictionary as! [String: Any])
        }
    }
}