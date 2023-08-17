//
//  FTEmojiesCategoryElement.swift
//  FTAddOperations
//
//  Created by Siva on 09/06/20.
//  Copyright © 2020 Siva. All rights reserved.
//

import Foundation

// MARK: - FTEmojiesCategoryElement
struct FTEmojiesCategory: Codable {
    let title: String
    var items: [FTEmojisItem]
}

// MARK: - Item
struct FTEmojisItem: Codable, Equatable {
    let emojiSymbol, keyword: String
}
