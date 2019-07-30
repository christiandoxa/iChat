//
// Created by Christian Doxa Hamasiah on 2019-07-30.
// Copyright (c) 2019 Christian Doxa Hamasiah. All rights reserved.
//

import Foundation
import IQAudioRecorderController

class AudioViewController {
    var delegate: IQAudioRecorderViewControllerDelegate

    init(delegate_: IQAudioRecorderViewControllerDelegate) {
        delegate = delegate_
    }

    func presentAudioRecorder(target: UIViewController) {
        let controller = IQAudioRecorderViewController()
        controller.delegate = delegate
        controller.title = "Record"
        controller.maximumRecordDuration = kAUDIOMAXDURATION
        controller.allowCropping = true
        target.presentBlurredAudioRecorderViewControllerAnimated(controller)
    }
}
