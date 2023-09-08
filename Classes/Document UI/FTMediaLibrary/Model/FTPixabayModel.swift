//
//  FTPixabayModel.swift
//  UnSplash
//
//  Created by Siva Kumar Reddy on 25/06/20.
//  Copyright © 2020 Siva Kumar Reddy. All rights reserved.
//

import Foundation

struct FTPixabayItem: Codable {
    let id: Int
    let tags: String
    let largeImageURL: String
    let webformatURL: String
    let previewURL: String
    var previewWidth, previewHeight: Int?

    func isMatching(with searchText: String) -> Bool {
        let searchString = searchText.lowercased()
        return  (self.tags.lowercased().contains(searchString))
    }

    func asOpenMediaLibrary() -> FTMediaLibraryModel {
        let openClipart = FTMediaLibraryModel(id: String(self.id), title: "customizeToolbar.pixabay".localized, clipartDescription: "customizeToolbar.pixabay".localized, tags: self.tags, width: previewWidth, height: previewHeight)
        openClipart.urls = FTOpenClipartURL(png_thumb: self.webformatURL, png_full_lossy: self.largeImageURL)
        return openClipart
    }
}

struct FTPixabayResponseModel: Decodable {
    let total: Int
    let totalHits: Int
    let hits: [FTPixabayItem]

    enum CodingKeys: String, CodingKey {
        case total = "total"
        case totalHits = "totalHits"
        case hits = "hits"
    }
}
