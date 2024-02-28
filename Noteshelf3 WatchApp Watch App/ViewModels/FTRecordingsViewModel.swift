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
   @Published var recordings: [FTRecording]

    var title: String {
        "Recordings"
    }
    
    init() {
        // dummy data
        let recording1 = FTRecording(duration: "35m 23s", dateTimeInfo: "06 Feb 24, 10:30")
        let recording2 = FTRecording(duration: "01h 2m 23s", dateTimeInfo: "02 Feb 24, 10:30")
        let recording3 = FTRecording(duration: "45m 30s", dateTimeInfo: "31 Jan 24, 15:00")
        self.recordings = [recording1, recording2, recording3]
    }
}
