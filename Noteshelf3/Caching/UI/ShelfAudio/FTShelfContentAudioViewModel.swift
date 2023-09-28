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
    weak var document: FTDocumentItemProtocol?

    var title: String {
        document?.displayTitle ?? ""
    }

    init(audioTitle: String, duration: String, page: Int, document: FTDocumentItemProtocol?) {
        self.page = page
        self.document = document
        self.audioTitle = audioTitle
        self.duration = duration
    }

    var isProtected: Bool {
        guard let url = document?.URL else {
            return false
        }

        return url.isPinEnabledForDocument()
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
            let media = try await fetchAudio()
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
    private func setMedia(_ audio: [FTShelfAudio]) {
        if audio.isEmpty {
            state = .empty
        } else {
            state = .loaded
        }
        self.audio = audio
    }
}

//TODO:(AK) Refactor to remove duplicate code from media
private extension FTShelfContentAudioViewModel {
    func fetchAudio() async throws -> [FTShelfAudio] {
        let allItems = await FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.byName, parent: nil, searchKey: nil)
        var totalMedia: [FTShelfAudio] = [FTShelfAudio]()


        let items: [FTDocumentItemProtocol] = allItems.filter({ ($0.URL.downloadStatus() == .downloaded) }).compactMap({ $0 as? FTDocumentItemProtocol })

        for case let item in items where item.documentUUID != nil {
            do {
                let media = try fetchMedia(docItem: item)
                totalMedia.append(contentsOf: media)
            } catch {
                continue
            }
        }
        cacheLog(.info, "totalMedia", totalMedia.count)
        return totalMedia
    }

    func fetchMedia(docItem: FTDocumentItemProtocol) throws -> [FTShelfAudio] {
        guard let docUUID = docItem.documentUUID, docItem.URL.downloadStatus() == .downloaded else { throw FTCacheError.documentNotDownloaded }

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
