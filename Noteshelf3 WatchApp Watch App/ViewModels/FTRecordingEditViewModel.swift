//
//  FTRecordingEditViewModel.swift
//  Noteshelf3 WatchApp
//
//  Created by Narayana on 14/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTRecordingEditViewModel: NSObject {
    private(set) var recording: FTWatchRecording

    var deleteConfirmInfo: String {
        "Are you sure you want to delete this recording?"
    }

    init(recording: FTWatchRecording) {
        self.recording = recording
    }

    func deleteRecording(completion:@escaping ((Bool?)->Void)) {
        FTWatchRecordingProvider.shared.deleteRecording(item: recording) { error in
            if let err = error {
                debugLog(err.localizedDescription)
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    func renameRecording(with name: String, completion:@escaping ((Bool?)->Void)) {
        guard !name.isEmpty else {
            completion(false)
            return
        }
        self.recording.audioTitle = name
        FTWatchRecordingProvider.shared.updateRecording(item: self.recording) { error in
            if let err = error {
                debugLog(err.localizedDescription)
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    func handleAction(for option: FTRecordingEditOption) {
        if option == .delete {
        }
    }

}

enum FTRecordingEditOption: String, CaseIterable {
    case rename
    case delete

    var title: String {
        let reqTitle: String
        if self == .rename {
            reqTitle = "Rename"
        } else {
            reqTitle = "Delete"
        }
        return reqTitle
    }

    var imageName: String {
        let reqImage: String
        if self == .rename {
            reqImage = "pencil"
        } else {
            reqImage = "trash"
        }
        return reqImage
    }
}
