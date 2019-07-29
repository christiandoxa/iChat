//
// Created by Christian Doxa Hamasiah on 2019-07-28.
// Copyright (c) 2019 Christian Doxa Hamasiah. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

class Camera {
    var delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate

    init(delegate_: UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
        delegate = delegate_
    }

    func PresentPhotoLibrary(target: UIViewController, canEdit: Bool) {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController
                .SourceType.photoLibrary) && !UIImagePickerController
                .isSourceTypeAvailable(UIImagePickerController.SourceType
                .savedPhotosAlbum) {
            return
        }
        let type = kUTTypeImage as String
        let imagePicker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.sourceType = .photoLibrary
            if let availableTypes = UIImagePickerController.availableMediaTypes(for:
            .photoLibrary) {
                if (availableTypes as NSArray).contains(type) {
                    /* Set up defaults */
                    imagePicker.mediaTypes = [type]
                    imagePicker.allowsEditing = canEdit
                }
            }
        } else if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            imagePicker.sourceType = .savedPhotosAlbum
            if let availableTypes = UIImagePickerController.availableMediaTypes(for:
            .savedPhotosAlbum) {
                if (availableTypes as NSArray).contains(type) {
                    imagePicker.mediaTypes = [type]
                }
            }
        } else {
            return
        }
        imagePicker.allowsEditing = canEdit
        imagePicker.delegate = delegate
        // presents the imagepicker to the user
        target.present(imagePicker, animated: true, completion: nil)
    }

    func PresentMultiCamera(target: UIViewController, canEdit: Bool) {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController
                .SourceType.camera) {
            return
        }
        let type1 = kUTTypeImage as String
        let type2 = kUTTypeMovie as String
        let imagePicker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            if let availableTypes = UIImagePickerController.availableMediaTypes(for:
            .camera) {
                if (availableTypes as NSArray).contains(type1) {
                    imagePicker.mediaTypes = [type1, type2]
                    imagePicker.sourceType = UIImagePickerController.SourceType.camera
                }
            }
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                imagePicker.cameraDevice = UIImagePickerController.CameraDevice.rear
            } else if UIImagePickerController.isCameraDeviceAvailable(.front) {
                imagePicker.cameraDevice = UIImagePickerController.CameraDevice.front
            }
        } else {
            //show alert, no camera available
            return
        }
        imagePicker.allowsEditing = canEdit
        imagePicker.showsCameraControls = true
        imagePicker.delegate = delegate
        // presents the imagepicker to the user
        target.present(imagePicker, animated: true, completion: nil)
    }

    func PresentPhotoCamera(target: UIViewController, canEdit: Bool) {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController
                .SourceType.camera) {
            return
        }
        let type1 = kUTTypeImage as String
        let imagePicker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            if let availableTypes = UIImagePickerController.availableMediaTypes(for:
            .camera) {
                if (availableTypes as NSArray).contains(type1) {
                    imagePicker.mediaTypes = [type1]
                    imagePicker.sourceType = UIImagePickerController.SourceType.camera
                }
            }
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                imagePicker.cameraDevice = UIImagePickerController.CameraDevice.rear
            } else if UIImagePickerController.isCameraDeviceAvailable(.front) {
                imagePicker.cameraDevice = UIImagePickerController.CameraDevice.front
            }
        } else {
            //show alert, no camera available
            return
        }
        imagePicker.allowsEditing = canEdit
        imagePicker.showsCameraControls = true
        imagePicker.delegate = delegate
        // presents the imagepicker to the user
        target.present(imagePicker, animated: true, completion: nil)
    }

    // Video Camera
    func PresentVideoCamera(target: UIViewController, canEdit: Bool) {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController
                .SourceType.camera) {
            return
        }
        let type1 = kUTTypeMovie as String
        let imagePicker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            if let availableTypes = UIImagePickerController.availableMediaTypes(for:
            .camera) {
                if (availableTypes as NSArray).contains(type1) {
                    imagePicker.mediaTypes = [type1]
                    imagePicker.sourceType = UIImagePickerController.SourceType.camera
                    imagePicker.videoMaximumDuration = kMAXDURATION
                }
            }
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                imagePicker.cameraDevice = UIImagePickerController.CameraDevice.rear
            } else if UIImagePickerController.isCameraDeviceAvailable(.front) {
                imagePicker.cameraDevice = UIImagePickerController.CameraDevice.front
            }
        } else {
            //show alert, no camera available
            return
        }
        imagePicker.allowsEditing = canEdit
        imagePicker.showsCameraControls = true
        imagePicker.delegate = delegate
        // presents the imagepicker to the user
        target.present(imagePicker, animated: true, completion: nil)
    }

    //video library
    func PresentVideoLibrary(target: UIViewController, canEdit: Bool) {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController
                .SourceType.photoLibrary) && !UIImagePickerController
                .isSourceTypeAvailable(UIImagePickerController.SourceType
                .savedPhotosAlbum) {
            return
        }
        let type = kUTTypeMovie as String
        let imagePicker = UIImagePickerController()
        imagePicker.videoMaximumDuration = kMAXDURATION
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.sourceType = .photoLibrary
            if let availableTypes = UIImagePickerController.availableMediaTypes(for:
            .photoLibrary) {
                if (availableTypes as NSArray).contains(type) {
                    /* Set up defaults */
                    imagePicker.mediaTypes = [type]
                    imagePicker.allowsEditing = canEdit
                }
            }
        } else if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            imagePicker.sourceType = .savedPhotosAlbum
            if let availableTypes = UIImagePickerController.availableMediaTypes(for:
            .savedPhotosAlbum) {
                if (availableTypes as NSArray).contains(type) {
                    imagePicker.mediaTypes = [type]
                }
            }
        } else {
            return
        }
        imagePicker.allowsEditing = canEdit
        imagePicker.delegate = delegate
        // presents the imagepicker to the user
        target.present(imagePicker, animated: true, completion: nil)
    }
}
