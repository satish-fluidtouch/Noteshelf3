//
//  FTSavedClipsViewModel.swift
//  Noteshelf3
//
//  Created by Siva on 20/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTSavedClipsViewModel {

    private let handler = FTSavedClipsProvider.shared
    private var categories = [FTSavedClipsCategoryModel]()

    func savedClipsCategories() -> [FTSavedClipsCategoryModel] {
        if let savedClipsCategories = try? handler.savedClipsCategories() {
            categories = savedClipsCategories
            return savedClipsCategories
        }
        return []
    }

    func deleteSavedClip(clip: FTSavedClipModel) throws {
       try handler.deleteSavedClipFor(category: clip.categoryTitle, fileName: clip.title)
    }

    func deleteCategory(category: String) throws {
        try handler.deleteCategory(category: category)
    }

    func clipAnnotationsFor(clip: FTSavedClipModel) async throws -> [FTAnnotation]? {
        return try await withCheckedThrowingContinuation { continuation in
        if let fileUrl = handler.fileUrlForClip(clip: clip) {
            let request = FTDocumentOpenRequest(url: fileUrl, purpose: .read)
                FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let document, let firstPage = document.pages().first {
                        let annotations = firstPage.annotations()
                        FTNoteshelfDocumentManager.shared.closeDocument(document: document, token: token, onCompletion: nil)
                        continuation.resume(returning: annotations)
                    }
                }
            }
        }
    }

    func numberOfRowsFor(indexPath: IndexPath) ->  Int {
        if categories.count > 0 {
            let savedClips = categories[indexPath.item].savedClips
            return savedClips.count
        }
        return 0
    }

}
