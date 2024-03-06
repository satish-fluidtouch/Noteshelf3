//
//  FTRecordViewModel.swift
//  Noteshelf3 WatchApp
//
//  Created by Narayana on 06/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import AVFAudio

class FTRecordViewModel: NSObject {
    private var recordingSession: AVAudioSession!

    func recordAudio() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)

    }
}
