//
//  FTStickerModels.swift
//  Noteshelf3
//
//  Created by Rakesh on 27/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI

enum StickerType: Codable {
    case staticSticker
    case downloadedSticker
}

struct FTStickerContainerResponseModel : Codable {
    var stickers: [FTStickerCategory]
}

struct FTStickerCategory: Codable {
    let title, type: String
    let subcategories: [FTStickerSubCategory]
}

struct FTStickerSubCategory: Codable {
    let title, image,filename: String
    let stickerItems: [FTStickerItem]
    var type: StickerType? = .staticSticker
}

struct FTStickerItem: Codable, Equatable {
    let image: String
}
