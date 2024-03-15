//
//  FTFileItemTemporary.swift
//  Noteshelf3
//
//  Created by Akshay on 26/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import FTDocumentFramework

protocol FTFileItemTemporary {
    init?(fileName: String, sourceURL: URL, content: NSObject?)
}

private extension FTFileItemTemporary {
    static func temporaryLocationForFile() -> URL {
        let temporaryLocation = URL.libraryDirectory.appending(path: "DeepCopy")
        var isDir = ObjCBool(false);
        if !FileManager.default.fileExists(atPath: temporaryLocation.path, isDirectory: &isDir) || !isDir.boolValue {
            try? FileManager().createDirectory(at: temporaryLocation, withIntermediateDirectories: true);
        }
        return temporaryLocation.appending(path: UUID().uuidString, directoryHint: .notDirectory)
    }
}

class FTFileItemImageTemporary: FTFileItemImage, FTFileItemTemporary {
    private var temporaryLocation: URL?

    required init?(fileName: String, sourceURL: URL, content: NSObject?) {
        let temporaryLocation = Self.temporaryLocationForFile()
        do {
            if content == nil {
                try FileManager.default.coordinatedCopy(fromURL: sourceURL, toURL: temporaryLocation)
                self.temporaryLocation = temporaryLocation
            }
            super.init(fileName: fileName, isDirectory: false)
            self.updateContent(content)
        } catch {
            debugLog("Unable to temp copy image error \(error)")
            return nil
        }
    }

    override func saveContentsOfFileItem() -> Bool {
        guard let temporaryLocation else {
            return super.saveContentsOfFileItem()
        }

        // Perform save to main document from the temporary location
        do {
            try FileManager.default.moveItem(at: temporaryLocation, to: self.fileItemURL)
            // reset the temp URL to nil so that this class acts like a normal file item.
            self.temporaryLocation = nil
            return true
        } catch {
            return false
        }
    }
}

class FTFileItemAudioTemporary: FTFileItemAudio, FTFileItemTemporary {
    private var temporaryLocation: URL?

    required init?(fileName: String, sourceURL: URL, content: NSObject?) {
        let temporaryLocation = Self.temporaryLocationForFile()
        do {
            try FileManager.default.coordinatedCopy(fromURL: sourceURL, toURL: temporaryLocation)
            self.temporaryLocation = temporaryLocation
            super.init(fileName: fileName, isDirectory: false)
            self.updateContent(content)
        } catch {
            debugLog("Unable to temp copy audio error \(error)")
            return nil
        }
    }

    override func saveContentsOfFileItem() -> Bool {
        guard let temporaryLocation else {
            return super.saveContentsOfFileItem()
        }

        // Perform save to main document from the temporary location
        do {
            try FileManager.default.moveItem(at: temporaryLocation, to: self.fileItemURL)
            // reset the temp URL to nil so that this class acts like a normal file item.
            self.temporaryLocation = nil
            return true
        } catch {
            return false
        }
    }
}
