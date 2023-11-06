//
//  FTShelfContentAudioViewModel.swift
//  Noteshelf3
//
//  Created by Akshay on 09/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Combine
import Foundation

class FTShelfAudio: Identifiable {
    let id: UUID = UUID()
    let page: Int
    let audioTitle: String
    let duration: String
    let dateAndTime: String
    weak var document: FTDocumentItemProtocol?

    var title: String {
        document?.displayTitle ?? ""
    }

    init(audioTitle: String, duration: String, page: Int, document: FTDocumentItemProtocol?, dateAndTime: String) {
        self.page = page
        self.document = document
        self.audioTitle = audioTitle
        self.duration = duration
        self.dateAndTime = dateAndTime
    }
}

final class FTShelfContentAudioViewModel: ObservableObject {
    @Published private(set) var audio: [FTShelfAudio] = []
    @Published private(set) var state: FTMediaLoadState = .loading

    var onSelect: ((_ audio: FTShelfAudio) -> Void)?
    var openInNewWindow: ((_ audio: FTShelfAudio) -> Void)?

    func buildCache() async {
        do {
            await startLoading()
            try await fetchAudio()
        } catch {
            cacheLog(.error, error)
        }
    }

    @MainActor
    private func startLoading() {
        state = .loading
    }

    @MainActor
    private func setState() {
        if self.audio.isEmpty {
            state = .empty
        } else {
            state = .loaded
        }
    }
    
    @MainActor
    private func updateMedia(items: [FTShelfAudio]) {
        self.audio.append(contentsOf: items)
        setState()
    }
}

//TODO:(AK) Refactor to remove duplicate code from media
private extension FTShelfContentAudioViewModel {
    func fetchAudio() async throws {
        let allItems = await FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.byName, parent: nil, searchKey: nil)
        let items: [FTDocumentItemProtocol] = allItems.compactMap({ $0 as? FTDocumentItemProtocol }).filter({ $0.isDownloaded })
        for case let item in items where item.documentUUID != nil {
            do {
                let media = try fetchMedia(docItem: item)
                await self.updateMedia(items: media)
            } catch {
                continue
            }
        }
    }

    func fetchMedia(docItem: FTDocumentItemProtocol) throws -> [FTShelfAudio] {
        guard let docUUID = docItem.documentUUID, docItem.isDownloaded else { throw FTCacheError.documentNotDownloaded }

        let cachedLocationURL = FTDocumentCache.shared.cachedLocation(for: docUUID)
        let annotationsFolder = cachedLocationURL.path.appending("/Annotations/")
        guard FileManager.default.fileExists(atPath: annotationsFolder) else {
            return []
        }
        let sqliteFiles = try FileManager.default.contentsOfDirectory(atPath: annotationsFolder)
        var totalMedia: [FTShelfAudio] = [FTShelfAudio]()

        for sqliteFile in sqliteFiles {
            let sqlitePath = annotationsFolder.appending(sqliteFile)
            let cachedFile = FTCachedSqliteAnnotationFileItem(url: URL(fileURLWithPath: sqlitePath), isDirectory: false, documentItem: docItem)
            let media = cachedFile.audioAnnotataions()
            totalMedia.append(contentsOf: media)
        }
        return totalMedia
    }
}
