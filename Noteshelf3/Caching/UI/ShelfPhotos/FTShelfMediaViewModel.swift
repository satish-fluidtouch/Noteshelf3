//
//  FTShelfContentPhotosViewModel.swift
//  Noteshelf
//
//  Created by Akshay on 21/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Combine
import Foundation

enum FTMediaLoadState {
    case loading
    case loaded
    case empty
}


class FTShelfMedia: Identifiable {
    let id: UUID = UUID()
    let page: Int
    let imageURL: URL
    weak var document: FTDocumentItemProtocol?
    var title: String {
        document?.displayTitle ?? ""
    }

    init(imageURL: URL, page: Int, document: FTDocumentItemProtocol?) {
        self.page = page
        self.imageURL = imageURL
        self.document = document
    }

    var isProtected: Bool {
        guard let url = document?.URL else {
            return false
        }

        return url.isPinEnabledForDocument()
    }
}

final class FTShelfContentPhotosViewModel: ObservableObject {
    @Published private(set) var media: [FTShelfMedia] = []
    @Published private(set) var state: FTMediaLoadState = .loading

    var onSelect: ((_ media: FTShelfMedia) -> Void)?
    var openInNewWindow: ((_ media: FTShelfMedia) -> Void)?

    func buildCache() async {
        do {
            await startLoading()
            let media = try await fetchMedia()
            await setMedia(media)
        } catch {
            cacheLog(.error, error)
        }
    }

    @MainActor
    private func startLoading() {
        state = .loading
    }

    @MainActor
    private func setMedia(_ media: [FTShelfMedia]) {
        if media.isEmpty {
            state = .empty
        } else {
            state = .loaded
        }
        self.media = media
    }
}


private extension FTShelfContentPhotosViewModel {
    func fetchMedia() async throws -> [FTShelfMedia] {
        let allItems = await FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.byName, parent: nil, searchKey: nil)
        var totalMedia: [FTShelfMedia] = [FTShelfMedia]()

        let items: [FTDocumentItemProtocol] = allItems.compactMap({ $0 as? FTDocumentItemProtocol }).filter({ $0.isDownloaded })

        for case let item in items where item.documentUUID != nil {
            do {
                let media = try fetchMedia(docItem: item)
                totalMedia.append(contentsOf: media)
            } catch {
                continue
            }
        }
        cacheLog(.success, totalMedia.count)
        return totalMedia
    }

    func fetchMedia(docItem: FTDocumentItemProtocol) throws -> [FTShelfMedia] {
        guard let docUUID = docItem.documentUUID, docItem.isDownloaded else { throw FTCacheError.documentNotDownloaded }

        let cachedLocationURL = FTDocumentCache.shared.cachedLocation(for: docUUID)
        let annotationsFolder = cachedLocationURL.path.appending("/Annotations/")
        guard FileManager.default.fileExists(atPath: annotationsFolder) else {
            return []
        }
        var sqliteFiles = try FileManager.default.contentsOfDirectory(atPath: annotationsFolder)
        var totalMedia: [FTShelfMedia] = [FTShelfMedia]()

        for sqliteFile in sqliteFiles {
            let sqlitePath = annotationsFolder.appending(sqliteFile)
            let cachedFile = FTCachedSqliteAnnotationFileItem(url: URL(fileURLWithPath: sqlitePath), isDirectory: false, documentItem: docItem)
            var media = cachedFile.annotataionsWithResources()
            totalMedia.append(contentsOf: media)
        }
        return totalMedia
    }
}
