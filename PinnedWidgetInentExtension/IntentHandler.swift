//
//  IntentHandler.swift
//  PinnedWidgetInentExtension
//
//  Created by Sameer Hussain on 13/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Intents
import FTCommon

// As an example, this class is set up to handle Message intents.
// You will want to replace this or add other intents as appropriate.
// The intents you wish to handle must be declared in the extension's Info.plist.

// You can test your example integration by saying things to Siri like:
// "Send a message using <myApp>"
// "<myApp> John saying hello"
// "Search for messages in <myApp>"

class IntentHandler: INExtension, FTPinnedIntentConfigurationIntentHandling {
    
    func provideBooksOptionsCollection(for intent: FTPinnedIntentConfigurationIntent) async throws -> INObjectCollection<FTPinnedBookType> {
        var items = [FTPinnedBookType]()
        let response = notebooks()
        response.forEach { eachItem in
            let pinnedItem = FTPinnedBookType(identifier: UUID().uuidString, display: eachItem.relativePath.lastPathComponent.deletingPathExtension)
            pinnedItem.coverImage = eachItem.coverImageName
            pinnedItem.time = eachItem.createdTime
            pinnedItem.relativePath = eachItem.relativePath
            pinnedItem.hasCover = NSNumber(booleanLiteral: eachItem.hasCover)
            items.append(pinnedItem)
        }
        let collection = INObjectCollection(items: items)
        return collection

    }
    
    override func handler(for intent: INIntent) -> Any {
        return self
    }
    
    private func notebooks() -> [FTPinnedMockData] {
        var notebooks = [FTPinnedMockData]()
        if FileManager().fileExists(atPath: sharedCacheURL.path(percentEncoded: false)) {
            if let urls = try? FileManager.default.contentsOfDirectory(at: sharedCacheURL,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles) {
                let notebookFilteredUrls = urls.filter { eachUrl in
                    return eachUrl.pathExtension == "ns3"
                }
                notebookFilteredUrls.forEach { eachNotebookUrl in
                    let relativePath : String
                    let time : String
                    let coverImage : String
                    let metaDataPlistUrl = eachNotebookUrl.appendingPathComponent("Metadata/Properties.plist")
                    relativePath = _relativePath(for: metaDataPlistUrl)
                    let isCover = hasCover(for: eachNotebookUrl.path(percentEncoded: false))
                    coverImage = eachNotebookUrl.appending(path:"cover-shelf-image.png").path(percentEncoded: false);
                    time = timeFromDate(currentDate: eachNotebookUrl.fileCreationDate)
                    let book = FTPinnedMockData(relativePath: relativePath, createdTime: time, coverImageName: coverImage, hasCover: isCover)
                    notebooks.append(book)
                }

            }
        }
        return notebooks
    }
    
    private func _relativePath(for metaDataPlistUrl: URL) -> String {
        var relativePath = ""
        if let data = try? Data(contentsOf: metaDataPlistUrl) {
            if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any], let _relativePath = plist["relativePath"] as? String {
                relativePath = _relativePath
            }
        }
        return relativePath
    }
    
    private func hasCover(for notebookPath: String) -> Bool {
        var hasCover = false
        let docPlist = notebookPath.appending("Document.plist")
        do {
            let url = URL(fileURLWithPath: docPlist)
            let dict = try NSDictionary(contentsOf: url, error: ())
            if let pagesArray = dict["pages"] as? [NSDictionary], let firstPage = pagesArray.first {
                hasCover = firstPage["isCover"] as? Bool ?? false
            }
        } catch {
            return hasCover
        }
        return hasCover
    }
    
    private func timeFromDate(currentDate: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.locale = .current // Set locale to ensure proper representation of AM/PM
        return dateFormatter.string(from: currentDate)
    }
    
    
    
    private var sharedCacheURL: URL {
        if let url = FileManager().containerURL(forSecurityApplicationGroupIdentifier: FTSharedGroupID.getAppGroupID()) {
            let directoryURL = url.appending(path: FTSharedGroupID.notshelfDocumentCache);
            return directoryURL
        }
        fatalError("Failed to get path");
    }
}

struct FTPinnedMockData {
    let relativePath: String
    let createdTime: String
    let coverImageName: String
    let hasCover: Bool
    
    init(relativePath: String, createdTime: String, coverImageName: String, hasCover: Bool) {
        self.relativePath = relativePath
        self.createdTime = createdTime
        self.coverImageName = coverImageName
        self.hasCover = hasCover
    }
    
    static let mockData: [[String: String]] = [
        [
            "bookName": "Notebook1",
            "createdTime": "5:00 PM",
            "imageName": "coverImage1"
        ],
        [
            "bookName": "Notebook2",
            "createdTime": "6:00 PM",
            "imageName": "coverImage2"
        ],
        [
            "bookName": "Notebook3",
            "createdTime": "7:00 PM",
            "imageName": "coverImage3"
        ],
        [
            "bookName": "Notebook4",
            "createdTime": "8:00 PM",
            "imageName": "coverImage4"
        ],
        [
            "bookName": "Notebook5",
            "createdTime": "9:00 PM",
            "imageName": "coverImage5"
        ],
        [
            "bookName": "Notebook6",
            "createdTime": "10:00 PM",
            "imageName": "coverImage6"
        ],
        [
            "bookName": "Notebook7",
            "createdTime": "11:00 PM",
            "imageName": "coverImage7"
        ],
        [
            "bookName": "Notebook8",
            "createdTime": "2:25 AM",
            "imageName": "coverImage8"
        ],
        [
            "bookName": "Notebook9",
            "createdTime": "1:025 AM",
            "imageName": "coverImage9"
        ],
        [
            "bookName": "Notebook10",
            "createdTime": "8:30 PM",
            "imageName": "coverImage10"
        ],
        [
            "bookName": "Notebook11",
            "createdTime": "12:25 PM",
            "imageName": "coverImage11"
        ]
    ]
}
