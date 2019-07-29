//
// Created by Christian Doxa Hamasiah on 2019-07-29.
// Copyright (c) 2019 Christian Doxa Hamasiah. All rights reserved.
//

import Foundation
import FirebaseStorage
import Firebase
import MBProgressHUD
import AVFoundation

let storage = Storage.storage()

func uploadImage(image: UIImage, chatRoomId: String, view: UIView,
                 completion: @escaping (_ imageLink: String?) -> Void) {
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    progressHUD.mode = .determinateHorizontalBar
    let dateString = dateFormatter().string(from: Date())
    let photoFileName = "PictureMessages/" + FUser.currentId() + "/" + chatRoomId
            + "/" + dateString + ".jpg"
    let storageReference = storage.reference(forURL: kFILEREFERENCE)
            .child(photoFileName)
    let imageData = image.jpegData(compressionQuality: 0.7)
    var task: StorageUploadTask!
    task = storageReference.putData(imageData!, metadata: nil) { metadata, error in
        task.removeAllObservers()
        progressHUD.hide(animated: true)
        if error != nil {
            print("error uploading image \(error!.localizedDescription)")
            return
        }
        storageReference.downloadURL { url, error in
            guard let downloadUrl = url else {
                completion(nil)
                return
            }
            completion(downloadUrl.absoluteString)
        }
    }
    task.observe(.progress) { snapshot in
        progressHUD.progress = Float((snapshot.progress!.completedUnitCount))
                / Float((snapshot.progress!.totalUnitCount))
    }
}
