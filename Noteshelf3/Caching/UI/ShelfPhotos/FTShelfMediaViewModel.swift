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

class FTShelfMedia: NSObject, Identifiable, ObservableObject {
    let id: UUID = UUID()
    let page: Int
    let imageURL: URL
    weak var document: FTDocumentItemProtocol?
    @Published var mediaImage : UIImage?
    var title: String {
        document?.displayTitle ?? ""
    }
    
    func fetchImage() {
        self.performSelector(inBackground: #selector(loadImageInBackground), with: nil)
    }
    
    @objc private func loadImageInBackground() {
        let hash = self.imageURL.thumbnailCacheHash()
        let cachedEntry = imageCache.object(forKey: hash as AnyObject)
        if let imageFromCache = cachedEntry?.object(forKey: "image") as? UIImage, let storedDate = cachedEntry?.object(forKey: "date") as? Date {
            if imageURL.fileModificationDate.compare(storedDate) != .orderedSame {
                 addImageTocache()
            } else {
                runInMainThread {
                    self.mediaImage = imageFromCache
                }
            }
        } else {
             addImageTocache()
        }
    }
    
    private func addImageTocache() {
        if let image = UIImage(contentsOfFile: self.imageURL.path()),  let thumbnailImage =  image.preparingThumbnail(of: CGSize(width: 400, height: 400)) {
            let hash = self.imageURL.thumbnailCacheHash()
            let entry: [String : Any] = ["image": thumbnailImage, "date": self.imageURL.fileModificationDate]
            imageCache.setObject(entry as AnyObject, forKey: hash as AnyObject)
            runInMainThread {
                self.mediaImage = thumbnailImage
            }
        }
    }

    func unloadImage() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(loadImageInBackground), object: nil)
        self.mediaImage =  nil
    }
  
    init(imageURL: URL, page: Int, document: FTDocumentItemProtocol?) {
        self.page = page
        self.imageURL = imageURL
        self.document = document
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

    private func updateMedia(items: [FTShelfMedia]) {
        runInMainThread {
            self.media.append(contentsOf: items)
            if self.state == .loaded, self.media.isEmpty {
                self.state = .empty
            } else {
                self.state = .loaded
            }
        }
    }
}


private extension FTShelfContentPhotosViewModel {
    func fetchMedia() async throws  {
        let allItems = await FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.byName, parent: nil, searchKey: nil)

        guard !allItems.isEmpty else {
            self.updateMedia(items: [])
            self.state = .loaded
            return
        }

        let items: [FTDocumentItemProtocol] = allItems.compactMap({ $0 as? FTDocumentItemProtocol }).filter({ $0.isDownloaded })

        for case let item in items where item.documentUUID != nil {
            do {
                try fetchMedia(docItem: item, onMediaFound: { [weak self] media in
                    self?.updateMedia(items: media)
                })
            } catch {
                continue
            }
        }
    }

    func fetchMedia(docItem: FTDocumentItemProtocol, onMediaFound: (_ media: [FTShelfMedia]) -> Void) throws {
        guard let docUUID = docItem.documentUUID, docItem.isDownloaded else { throw FTCacheError.documentNotDownloaded }

        let cachedLocationURL = FTDocumentCache.shared.cachedLocation(for: docUUID)
        let annotationsFolder = cachedLocationURL.path.appending("/Annotations/")
        guard FileManager.default.fileExists(atPath: annotationsFolder) else {
            onMediaFound([])
            return
        }
        var sqliteFiles = try FileManager.default.contentsOfDirectory(atPath: annotationsFolder)

        for sqliteFile in sqliteFiles {
            let sqlitePath = annotationsFolder.appending(sqliteFile)
            let cachedFile = FTCachedSqliteAnnotationFileItem(url: URL(fileURLWithPath: sqlitePath), isDirectory: false, documentItem: docItem)
            var media = cachedFile.annotataionsWithResources()
            onMediaFound(media)
        }
        onMediaFound([])
    }
}
