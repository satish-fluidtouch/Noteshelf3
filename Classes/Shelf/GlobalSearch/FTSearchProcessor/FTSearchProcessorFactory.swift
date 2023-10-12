//
//  FTSearchProcessorFactory.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 08/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSearchProcessorFactory: NSObject {
    static func getProcessor(forType type: FTGlobalSearchType, searchKey: String, tags: [String] = [], opQueue: OperationQueue?) -> FTSearchProcessor {
        let processor: FTSearchProcessor
        switch type {
        case .titles:
            processor = FTNotebookTitleSearchProcessor(with: searchKey, opQueue: opQueue)
        case .tags:
            processor = FTNotebookTagsSearchProcessor(with: tags)
        case .content:
            processor = FTNotebookContentSearchProcessor(with: searchKey, tags: tags, opQueue: opQueue)
        case .all:
            processor = FTNotebookAllSearchProcessor(with: searchKey, tags: tags, opQueue: opQueue)
        }
        return processor
    }
}
