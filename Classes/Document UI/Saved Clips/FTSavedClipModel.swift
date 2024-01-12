//
//  FTSavedClipModel.swift
//  Noteshelf3
//
//  Created by Siva on 20/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
// MARK: - FTSavedClipsCategoryModel
struct FTSavedClipsCategoryModel {
    var title: String
    var savedClips = [FTSavedClipModel]()
    init(title: String, savedClips: [FTSavedClipModel] = []) {
        self.title = title
        self.savedClips = savedClips
    }
}

// MARK: - FTSavedClipModel
struct FTSavedClipModel {
    var title: String
    var categoryTitle: String
    var image: UIImage?

    init(title: String, categoryTitle: String, image: UIImage?) {
        self.title = title
        self.image = image
        self.categoryTitle = categoryTitle
    }
}
