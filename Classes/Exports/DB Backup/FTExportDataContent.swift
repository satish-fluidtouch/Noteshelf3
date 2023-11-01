//
//  FTExportDataContent.swift
//  Noteshelf
//
//  Created by Akshay on 06/11/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTExportDataContent {
    private var itemsToExport : [FTItemToExport]
    private var completed = [FTItemToExport]()
    private var failed = [FTItemToExport]()

    private let totalItemCount : Int

    var currentProcessingItem: FTItemToExport?
    init(items:[FTItemToExport]) {
        self.itemsToExport = items
        totalItemCount = items.count
    }

    func messageForProgress() -> String {
        var info = NSLocalizedString("Generating", comment: "Generating...");
        if(totalItemCount > 1) {
            let str = String.init(format: NSLocalizedString("NofNAlt", comment: "%d of %d"), completed.count,totalItemCount);

            info = info.appending("\n").appending(str);
        }
        return info
    }

    var approximateZipProgress: Int64 {
        return max(1,Int64(Double(totalItemCount)*0.10))
    }

    mutating func nextItemToExport() -> FTItemToExport? {
        if itemsToExport.isEmpty == false {
            currentProcessingItem = itemsToExport.removeFirst()
            return currentProcessingItem
        } else {
            return nil
        }
    }

    mutating func exportSucceeded() {
        if let item = currentProcessingItem {
            completed.append(item)
        }
    }

    mutating func exportFailed() {
        if let item = currentProcessingItem {
            failed.append(item)
        }
    }

    func failedItemTitles() -> [String]? {
        guard !failed.isEmpty else { return nil }
        let names = failed.map { item -> String in
            return item.shelfItem.URL.displayRelativePathWRTCollection()
        }
        return names
    }
}
