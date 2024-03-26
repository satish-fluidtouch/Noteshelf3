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
    var url: URL?
    var savedClips = [FTSavedClipModel]()
    
    init(title: String, url: URL?, savedClips: [FTSavedClipModel] = []) {
        self.title = title
        self.url = url
        self.savedClips = savedClips
    }
}

// MARK: - FTSavedClipModel
struct FTSavedClipModel {
    var title: String
    var url: URL
    var categoryTitle: String
    var image: UIImage?

    init(title: String, url: URL, categoryTitle: String, image: UIImage?) {
        self.title = title
        self.url = url
        self.image = image
        self.categoryTitle = categoryTitle
    }
}
