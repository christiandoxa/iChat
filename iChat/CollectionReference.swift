//
//  CollectionReference.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 2019-07-24.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import Foundation
import FirebaseFirestore


enum FCollectionReference: String {
    case User
    case Typing
    case Recent
    case Message
    case Group
    case Call
}


func reference(_ collectionReference: FCollectionReference) -> CollectionReference {
    return Firestore.firestore().collection(collectionReference.rawValue)
}