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
    case partiallyLoaded
    case empty
}

fileprivate let imageCache = NSCache<AnyObject, AnyObject>()

class FTShelfMedia: NSObject, Identifiable, ObservableObject {
    let id: UUID = UUID()
    let page: Int
    let imageURL: URL
    weak var document: FTDocumentItemProtocol?
    @Published private(set) var mediaImage : UIImage?
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
                runInMainThread(0.5) {
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

    private(set) var progress: Progress = Progress()
    private var cancellables = Set<AnyCancellable>()

    var onSelect: ((_ media: FTShelfMedia) -> Void)?
    var openInNewWindow: ((_ media: FTShelfMedia) -> Void)?
    
    init() {
        self.progress.publisher(for: \.isFinished).sink { [weak self] isfinished in
            runInMainThread {
                self?.state = .loaded
                self?.updateMedia(items: [])
            }
        }.store(in: &cancellables)
    }

    func buildCache() async {
        do {
            await startLoading()
            try await fetchMedia()
        } catch {
            cacheLog(.error, error)
        }
    }
    
    func stopFetching() {
        progress.cancel()
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
                self.state = .partiallyLoaded
            }
        }
    }
}


private extension FTShelfContentPhotosViewModel {
    func fetchMedia() async throws  {
        let allItems = await FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.byName, parent: nil, searchKey: nil)
        
        let items: [FTDocumentItemProtocol] = allItems.compactMap({ $0 as? FTDocumentItemProtocol }).filter({ $0.isDownloaded })
        progress.totalUnitCount = Int64(items.count)

        guard !items.isEmpty else {
            self.state = .loaded
            self.updateMedia(items: [])
            progress.completedUnitCount = progress.totalUnitCount
            return
        }

        for case let item in items where !progress.isCancelled {
            do {
                try fetchMedia(docItem: item, onMediaFound: { [weak self] media in
                    self?.updateMedia(items: media)
                })
                progress.completedUnitCount += 1
            } catch {
                progress.completedUnitCount += 1
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
        let sqliteFiles = try FileManager.default.contentsOfDirectory(atPath: annotationsFolder)

        for sqliteFile in sqliteFiles where !progress.isCancelled {
            let sqlitePath = annotationsFolder.appending(sqliteFile)
            let cachedFile = FTCachedSqliteAnnotationFileItem(url: URL(fileURLWithPath: sqlitePath), isDirectory: false, documentItem: docItem)
            let media = cachedFile.annotataionsWithResources()
            onMediaFound(media)
        }
    }
}
