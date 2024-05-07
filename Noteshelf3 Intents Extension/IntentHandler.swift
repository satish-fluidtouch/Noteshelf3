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
        let response = FTWidgetIntentDataHelper.allNoteBooks
        response.forEach { eachItem in
            let pinnedItem = FTPinnedBookType(identifier: eachItem.docId, display: FTWidgetIntentDataHelper.displayName(from: eachItem.relativePath))
            pinnedItem.coverImage = eachItem.coverImageName
            pinnedItem.time = eachItem.createdTime
            pinnedItem.relativePath = eachItem.relativePath
            pinnedItem.hasCover = NSNumber(booleanLiteral: eachItem.hasCover)
            pinnedItem.isLandscape = NSNumber(booleanLiteral: eachItem.isLandscape)
            items.append(pinnedItem)
        }
        let collection = INObjectCollection(items: items)
        return collection

    }

    override func handler(for intent: INIntent) -> Any {
        return self
    }
}
