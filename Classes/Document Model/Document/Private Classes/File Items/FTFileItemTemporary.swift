//
//  FTFileItemTemporary.swift
//  Noteshelf3
//
//  Created by Akshay on 26/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import FTDocumentFramework

//----------------EXPERIMENTAL--------------//
// remove this after validation
private let usecoordinatedcopy = true
//----------------EXPERIMENTAL--------------//

protocol FTFileItemCacheble {
    init?(url: URL, sourceURL: URL)
}

class FTFileItemImageTemporary: FTFileItemImage, FTFileItemCacheble {
    private let temporaryLocation: URL

    required init?(url: URL, sourceURL: URL) {
        temporaryLocation = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .notDirectory)
        do {
            if usecoordinatedcopy {
                try FileManager.default.coordinatedCopy(fromURL: sourceURL, toURL: temporaryLocation)
            } else {
                try FileManager.default.copyItem(at: sourceURL, to: temporaryLocation)
            }
            super.init(url: url, isDirectory: false)
        } catch {
            print("Cacheable file item create error", error)
            return nil
        }
    }

    override func saveContentsOfFileItem() -> Bool {
        do {
            try FileManager.default.moveItem(at: temporaryLocation, to: self.fileItemURL)
            return true
        } catch {
            print("Cacheable file item save error", error)
            return false
        }
    }
}

class FTFileItemAudioTemporary: FTFileItemAudio, FTFileItemCacheble {
    private let temporaryLocation: URL

    required init?(url: URL, sourceURL: URL) {
        temporaryLocation = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .notDirectory)
        do {
            if usecoordinatedcopy {
                try FileManager.default.coordinatedCopy(fromURL: sourceURL, toURL: temporaryLocation)
            } else {
                try FileManager.default.copyItem(at: sourceURL, to: temporaryLocation)
            }
            super.init(url: url, isDirectory: false)
        } catch {
            print("Cacheable file item create error", error)
            return nil
        }
    }

    override func saveContentsOfFileItem() -> Bool {
        do {
            try FileManager.default.moveItem(at: temporaryLocation, to: self.fileItemURL)
            return true
        } catch {
            print("Cacheable file item save error", error)
            return false
        }
    }
}
