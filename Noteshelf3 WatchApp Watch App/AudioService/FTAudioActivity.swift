//
//  FTAudioActivity.swift
//  Noteshelf3
//
//  Created by Narayana on 06/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

@objc enum FTAudioServiceStatus: Int {
    case none
    case playing
    case playingPaused
    case recording
    case recordingPaused
}

var audioServiceCurrentState: FTAudioServiceStatus! = FTAudioServiceStatus.none
var recentPlayedAudio: Dictionary<String, Any>! = ["currentTime" : 0.0, "GUID": ""]

class FTAudioActivity: NSObject {
    var audioURL:URL?
    var totalDuration: TimeInterval = 0

    @objc var audioServiceStatus:FTAudioServiceStatus = FTAudioServiceStatus.none {
        willSet { // enum key value changes need to handle this way
            self.willChangeValue(forKey: #keyPath(FTAudioActivity.audioServiceStatus))
        }

        didSet {
            audioServiceCurrentState = audioServiceStatus
            self.didChangeValue(forKey: #keyPath(FTAudioActivity.audioServiceStatus))
#if DEBUG
            debugPrint("audioServiceCurrentState: \(["none","playing","recording","playingPaused", "recordingPaused"][audioServiceCurrentState.rawValue])")
#endif
        }
    }

    @objc var currentTime: TimeInterval = 0 {
        willSet {
            self.willChangeValue(forKey: "currentTime")
        }
        didSet {
            self.didChangeValue(forKey: "currentTime")
        }
    }
}
