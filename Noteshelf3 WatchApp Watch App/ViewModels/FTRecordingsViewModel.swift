//
//  FTRecordingsViewModel.swift
//  Noteshelf3 WatchApp Watch App
//
//  Created by Narayana on 28/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTRecording {
    let uuid = UUID()
    let duration: String
    let dateTimeInfo: String
}

class FTRecordingsViewModel: ObservableObject {
   @Published var recordings: [FTWatchRecording] = []

    var title: String {
        "Recordings"
    }

    func reloadRecordings() {
        FTWatchRecordingProvider.shared.allRecordings({ [weak self] (allRecordings) in
            guard let self else { return }
            self.recordings = allRecordings
        })
    }

    func deleteRecording(_ recording: FTWatchRecording) {
        FTWatchRecordingProvider.shared.deleteRecording(item: recording) { error in
            if nil == error {
                self.recordings.removeAll(where: { $0.GUID == recording.GUID })
            }
        }
    }
}
