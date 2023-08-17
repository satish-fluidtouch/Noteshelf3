//
//  FTCacheTags.swift
//  Noteshelf3
//
//  Created by Siva on 11/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTCacheTagsPlist: Codable {
    typealias tagName = String

    var tags: [tagName: [String]]
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        tags = try container.decode([tagName: [String]].self)
    }
}
