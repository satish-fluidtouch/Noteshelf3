//
//  FTSavedClipsViewModel.swift
//  Noteshelf3
//
//  Created by Siva on 20/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTSavedClipsViewModel {
    var showOrHideSegment:((Bool) -> Void)?
    var updatedSegmentSelection:((Int) -> Void)?
    var updateCellType:((Int) -> Void)?

    private let handler = FTSavedClipsProvider.shared
    private var categories = [FTSavedClipsCategoryModel]() {
        didSet {
            if categories.count > 1 {
                self.showOrHideSegment?(false)
            }
        }
    }

    init() {

        let categories = savedClipsCategories()
        let sortedArray = categories.sorted(by: {$0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending})
        self.categories = sortedArray
    }

    func savedClipsCategories() -> [FTSavedClipsCategoryModel] {
        if let savedClipsCategories = try? handler.savedClipsCategories() {
            return savedClipsCategories
        }
        return []
    }

    func categoriesCount() -> Int {
        return self.categories.count
    }

    func selectedIndex() -> Int {
        if let selectedCategory = FTUserDefaults.selectedClipCategory, let firstindex = categories.firstIndex(where: {$0.title == selectedCategory}) {
            return firstindex
        }
        return 0
    }

    func categoryNames() -> [String] {
        let titles = categories.map{ $0.title.localized }
        return titles
    }

    func numberOfRowsForSection(section: Int) ->  Int {
        if categories.count > 0 {
            let savedClips = categories[section].savedClips
            return savedClips.count
        }
        return 0
    }

    func itemFor(indexPath: IndexPath) -> FTSavedClipModel? {
        if categories.count > indexPath.section {
            let savedClips = categories[indexPath.section].savedClips
            let clip = savedClips[indexPath.item]
            return clip
        }
        return nil
    }

    func categoryFor(index: Int) -> FTSavedClipsCategoryModel? {
        if categories.count > index {
            let category = categories[index]
            return category
        }
        return nil
    }

    func removeItemFor(indexPath: IndexPath) throws {
        if categories.count > indexPath.section {
            let savedClips = categories[indexPath.section].savedClips
            let clip = savedClips[indexPath.item]
            try handler.removeClip(clip: clip)
            self.categories[indexPath.section].savedClips.remove(at: indexPath.item)
        }
    }

    func removeCategory(index: Int) throws {
        if categories.count > 0 {
            let category = categories[index]
            try handler.removeCategory(category: category)
            self.categories.remove(at: index)
            updatedSegmentSelection?(categories.count)
        }

    }

    func renameCategory(category: FTSavedClipsCategoryModel, with fileName: String) throws {
        if let url = try handler.renameCategory(category: category, with: fileName),   let index = self.categories.firstIndex(where: {$0.title == category.title}) {
            categories[index].title = fileName
            categories[index].url = url
        }
    }

    func clipAnnotationsFor(clip: FTSavedClipModel, completion: @escaping ([FTAnnotation]?, Error?) -> Void)  {
        if let fileUrl = handler.fileUrlForClip(clip: clip) {
            let request = FTDocumentOpenRequest(url: fileUrl, purpose: .read)
            FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                if let error {
                    completion(nil, error)
                } else if let document, let firstPage = document.pages().first {
                    let annotations = firstPage.annotations()
                    FTNoteshelfDocumentManager.shared.closeDocument(document: document, token: token, onCompletion: nil)
                    completion(annotations, nil)
                }
            }
        }
    }

}
