//
//  FTShelfCompactContentContainerView.swift
//  Noteshelf3
//
//  Created by Akshay on 19/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTShelfPageModel {
    let pageId: Int
    let title: String
    let icon: Image
    init(pageId: Int, title: String, icon: Image) {
        self.pageId = pageId
        self.title = title
        self.icon = icon
    }
}

struct FTShelfCompactContentContainerView: View {
    var photosViewModel = FTShelfContentPhotosViewModel()
    var audioViewModel = FTShelfContentAudioViewModel()
    var bookmarkViewModel = FTShelfBookmarksPageModel()

    var body: some View {
        FTShelfContentCompactView(content: [
            FTShelfPageModel(pageId: 0, title: "Photos",icon: Image(systemName: "photo.on.rectangle.angled")),
            FTShelfPageModel(pageId: 1, title: "Audios", icon: Image(systemName: "mic")),
            FTShelfPageModel(pageId: 2, title: "Bookmarks", icon: Image(systemName: "bookmark"))
        ])
            .navigationTitle("shelf.sidebar.content".localized)
    }
}
