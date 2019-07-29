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

func downloadImage(imageUrl: String, completion: @escaping (_ image: UIImage?) -> Void) {
    let imageURL = NSURL(string: imageUrl)
    print(imageUrl)
    let imageFileName = (imageUrl.components(separatedBy: "%").last!)
            .components(separatedBy: "?").first
    print("file name \(imageFileName!)")
    if fileExistsAtPath(path: imageFileName!) {
        if let contentsOfFile = UIImage(contentsOfFile: fileInDocumentsDirectory(fileName: imageFileName!)) {
            completion(contentsOfFile)
        } else {
            print("couldn't generate image")
            completion(nil)
        }
    } else {
        let downloadQueue = DispatchQueue(label: "imageDownloadQueue")
        downloadQueue.async {
            let data = NSData(contentsOf: imageURL! as URL)
            if data != nil {
                var docURL = getDocumentsUrl()
                docURL = docURL.appendingPathComponent(imageFileName!, isDirectory: false)
                data!.write(to: docURL, atomically: true)
                let imageToReturn = UIImage(data: data! as Data)
                DispatchQueue.main.async {
                    completion(imageToReturn!)
                }
            } else {
                DispatchQueue.main.async {
                    print("no image in database")
                    completion(nil)
                }
            }
        }
    }
}

func fileInDocumentsDirectory(fileName: String) -> String {
    let fileUrl = getDocumentsUrl().appendingPathComponent(fileName)
    return fileUrl.path
}

func getDocumentsUrl() -> URL {
    let documentURL = FileManager.default.urls(for: .documentDirectory,
            in: .userDomainMask).last
    return documentURL!
}

func fileExistsAtPath(path: String) -> Bool {
    var doesExist = false
    let filePath = fileInDocumentsDirectory(fileName: path)
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: filePath) {
        doesExist = true
    } else {
        doesExist = false
    }
    return doesExist
}
