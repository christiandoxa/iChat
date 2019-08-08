//
//  AudioControllerDelegate.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 09/08/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import Foundation

class AudioControllerDelegate: NSObject, SINAudioControllerDelegate {
    var muted: Bool!
    var speaker: Bool!

    func audioControllerMuted(_ audioController: SINAudioController!) {
        self.muted = true
    }

    func audioControllerUnmuted(_ audioController: SINAudioController!) {
        self.muted = false
    }

    func audioControllerSpeakerEnabled(_ audioController: SINAudioController!) {
        self.speaker = true
    }

    func audioControllerSpeakerDisabled(_ audioController: SINAudioController!) {
        self.speaker = false
    }
}
