//
//  FTUnSplashModel.swift
//  UnSplash
//
//  Created by Siva Kumar Reddy on 25/06/20.
//  Copyright © 2020 Siva Kumar Reddy. All rights reserved.
//

import FTNewNotebook

extension FTUnSplashItem {
    func asOpenClipart1() -> FTMediaLibraryModel {
        let openClipart = FTMediaLibraryModel(id: self.id, title: "Unsplash", clipartDescription: "UnSplash", user: user, width: width, height: height, unSplashTags: tags)
        openClipart.urls = FTOpenClipartURL(png_thumb: self.urls?.small ?? "", png_full_lossy: self.urls?.regular  ?? "")
        openClipart.links = FTOpenClipartResultLinks(download_location: links?.downloadLocation ?? "")
        return openClipart
    }
}
