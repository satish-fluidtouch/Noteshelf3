//
//  FTDocumentTags.swift
//  Noteshelf3
//
//  Created by Siva on 11/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTDocumentPage: Decodable, Identifiable, Hashable {
    var uuid: String

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(uuid)
    }

    public static func == (lhs: FTDocumentPage, rhs: FTDocumentPage) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    var tags: [String]
}

class FTDocumentPlist: Decodable {
    var pages: [FTDocumentPage]
}
