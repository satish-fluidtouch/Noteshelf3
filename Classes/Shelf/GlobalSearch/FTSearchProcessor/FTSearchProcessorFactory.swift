//
//  FTSearchProcessorFactory.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 08/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSearchProcessorFactory: NSObject {
    static func getProcessor(forType type: FTGlobalSearchType, searchKey: String, tags: [String] = []) -> FTSearchProcessor {
        if type == .titles {
            return FTNotebookTitleSearchProcessor.init(with: searchKey)
        } else if type == .tags {
            return FTNotebookTagsSearchProcessor(with: tags)
        } else if type == .content {
            return FTNotebookContentSearchProcessor.init(with: searchKey, tags: tags)
        }
        return FTNotebookAllSearchProcessor.init(with: searchKey, tags: tags)
    }
}
