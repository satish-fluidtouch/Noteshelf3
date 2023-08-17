//
//  FTNoResultsViewHostingController.swift
//  Noteshelf
//
//  Created by Narayana on 08/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

class FTNoResultsViewHostingController: UIHostingController<FTNoResultsView> {
    init(imageName: String, title: String, description: String, learmoreLink: String = "", showLink: Bool = false) {
        super.init(rootView: FTNoResultsView(noResultsImageName: imageName, title: title, description: description, learnMoreLink: learmoreLink, showLearnMoreLink: showLink))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FTFinderNoResultsViewHostingController: FTNoResultsViewHostingController {
    init(segment: FTFinderSegment) {
        super.init(imageName: "emptySearch", title: "", description: "")
        updateView(for: segment)
    }

    func updateView(for segment: FTFinderSegment) {
        var imgName: String = "emptySearch"
        var title: String = ""
        var description: String = ""

        if segment == .bookmark {
            imgName = "noBookmarks"
            title = "finder.bookmarks".localized
            description = "finder.bookmark.description".localized
        } else if segment == .outlines {
            imgName = "outline"
            title = "finder.outline".localized
            description = "finder.outline.description".localized
        } else if segment == .search {
            imgName = "emptySearch"
            title = "NoResults".localized
            description = "search.tryNewSearch".localized
        }
        rootView = FTNoResultsView(noResultsImageName: imgName, title: title, description: description)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
