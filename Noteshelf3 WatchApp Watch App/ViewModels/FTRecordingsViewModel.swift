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
    
    init() {
        FTWatchRecordingProvider.shared.allRecordings({ [weak self] (allRecordings) in
            guard let self else { return }
            self.recordings = allRecordings
            if (allRecordings.count > 0) {
                    
            } else {
                // TODO:  -> Dummy Data to be removed later
                let rec1 = FTWatchRecordedAudio(GUID: "1", date: Date().addingTimeInterval(-120000), duration: 1000)
                let rec2 = FTWatchRecordedAudio(GUID: "2", date: Date().addingTimeInterval(-60000), duration: 2000)
                let rec3 = FTWatchRecordedAudio(GUID: "3", date: Date(), duration: 3000)
                self.recordings.append(contentsOf: [rec1, rec2, rec3])
            }
        })
    }
}
