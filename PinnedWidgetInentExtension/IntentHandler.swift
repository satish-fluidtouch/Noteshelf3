//
//  IntentHandler.swift
//  PinnedWidgetInentExtension
//
//  Created by Sameer Hussain on 13/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Intents

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
        let response = FTPinnedMockData.mockData
        response.forEach { eachItem in
            let pinnedItem = FTPinnedBookType(identifier: UUID().uuidString, display: eachItem["bookName"] ?? "")
            
            pinnedItem.coverImage = eachItem["imageName"]
            pinnedItem.time = eachItem["createdTime"]
            items.append(pinnedItem)
        }
        let collection = INObjectCollection(items: items)
        return collection

    }
    
    override func handler(for intent: INIntent) -> Any {
        return self
    }
}

struct FTPinnedMockData {
    let bookName: String
    let createdTime: String
    let coverImageName: String
    
    init(bookName: String, createdTime: String, coverImageName: String) {
        self.bookName = bookName
        self.createdTime = createdTime
        self.coverImageName = coverImageName
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
        ]
    ]
}
