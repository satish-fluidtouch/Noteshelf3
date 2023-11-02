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

fileprivate let imageCache = NSCache<AnyObject, AnyObject>()

class FTShelfMedia: Identifiable, ObservableObject {
    let id: UUID = UUID()
    let page: Int
    let imageURL: URL
    weak var document: FTDocumentItemProtocol?
    @Published var mediaImage : UIImage?
    var title: String {
        document?.displayTitle ?? ""
    }
    
    @MainActor
    private func updateImage(image: UIImage?) {
        self.mediaImage = image
    }
    
    func loadImageAsynchronously() async {
        let urlString = self.imageURL.path
        if let imageFromCache = imageCache.object(forKey: urlString as AnyObject) as? UIImage {
            await updateImage(image: imageFromCache)
        } else {
            if let image = UIImage(contentsOfFile: self.imageURL.path()),  let thumbnailImage = await image.byPreparingThumbnail(ofSize: CGSize(width: 400, height: 400)) {
                imageCache.setObject(thumbnailImage, forKey: urlString as AnyObject)
                await updateImage(image: thumbnailImage)
            }
        }
    }
    
    func unloadImage() {
        self.mediaImage =  nil
    }
  
    init(imageURL: URL, page: Int, document: FTDocumentItemProtocol?) {
        self.page = page
        self.imageURL = imageURL
        self.document = document
    }

    var isProtected: Bool {
        guard let doc = document else {
            return false
        }

        return doc.isPinEnabledForDocument()
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
            try await fetchMedia()
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
        if self.media.isEmpty {
            state = .empty
        } else {
            state = .loaded
        }
    }
    
    @MainActor
    private func updateMedia(items: [FTShelfMedia]) {
        self.media.append(contentsOf: items)
        setState()
    }
}


private extension FTShelfContentPhotosViewModel {
    func fetchMedia() async throws  {
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
