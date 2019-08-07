//
// Created by Christian Doxa Hamasiah on 2019-08-07.
// Copyright (c) 2019 Christian Doxa Hamasiah. All rights reserved.
//

import Foundation
import OneSignal

func sendPushNotifications(memberToPush: [String], message: String) {
    let updatedMembers = removeCurrentUserFromMembersArray(members: memberToPush)
    getMembersToPush(members: updatedMembers) { userPushIds in
        let currentUser = FUser.currentUser()!
        OneSignal.postNotification([
            "contents": ["en": "\(currentUser.firstname)\n\(message)"],
            "ios_badgeType": "Increase",
            "ios_badgeCount": "1",
            "include_player_ids": userPushIds
        ])
    }
}

func removeCurrentUserFromMembersArray(members: [String]) -> [String] {
    var updatedMembers: [String] = []
    for member in members {
        if member != FUser.currentId() {
            updatedMembers.append(member)
        }
    }
    return updatedMembers
}

func getMembersToPush(members: [String], completion: @escaping (_ usersArray: [String]) -> Void) {
    var pushIds: [String] = []
    var count = 0
    for memberId in members {
        reference(.User).document(memberId).getDocument { snapshot, error in
            guard snapshot != nil else {
                completion(pushIds)
                return
            }
            if snapshot!.exists {
                let userDictionary = snapshot!.data()! as NSDictionary
                let fUser = FUser(_dictionary: userDictionary)
                pushIds.append(fUser.pushId!)
                count += 1
                if members.count == count {
                    completion(pushIds)
                }
            } else {
                completion(pushIds)
            }
        }
    }
}
