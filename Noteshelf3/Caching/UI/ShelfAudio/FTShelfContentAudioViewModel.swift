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

    private var progress = Progress()
    private var cancellables = Set<AnyCancellable>()

    var onSelect: ((_ audio: FTShelfAudio) -> Void)?
    var openInNewWindow: ((_ audio: FTShelfAudio) -> Void)?
    
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
            try await fetchAudio()
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

    private func updateMedia(items: [FTShelfAudio]) {
        runInMainThread {
            self.audio.append(contentsOf: items)
            if self.state == .loaded, self.audio.isEmpty {
                self.state = .empty
            } else {
                self.state = .partiallyLoaded
            }
        }
    }
}

//TODO:(AK) Refactor to remove duplicate code from media
private extension FTShelfContentAudioViewModel {
    func fetchAudio() async throws {
        let allItems = await FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.byName, parent: nil, searchKey: nil)

        let items: [FTDocumentItemProtocol] = allItems.compactMap({ $0 as? FTDocumentItemProtocol }).filter({ $0.isDownloaded })
        progress.totalUnitCount = Int64(items.count)

        guard !items.isEmpty else {
            self.state = .loaded
            progress.completedUnitCount = progress.totalUnitCount
            self.updateMedia(items: [])
            return
        }

        for case let item in items where !progress.isCancelled {
            do {
                try fetchMedia(docItem: item) { [weak self] media in
                    self?.updateMedia(items: media)
                }
                progress.completedUnitCount += 1
            } catch {
                progress.completedUnitCount += 1
                continue
            }
        }
    }

    func fetchMedia(docItem: FTDocumentItemProtocol, onMediaFound: (_ media: [FTShelfAudio]) -> Void) throws {
        guard let docUUID = docItem.documentUUID, docItem.isDownloaded else { throw FTCacheError.documentNotDownloaded }

        guard let doc = FTDocumentCache.shared.cachedDocument(docUUID) else {
            onMediaFound([]);
            return;
        }
        
        doc.pages().forEach { eachpage in
            if let nonStrokeFleItem = doc.nonStrokeFileItem(eachpage.pageUUID) {
                let annotations = nonStrokeFleItem.annotations(types: [.audio])
                var mediaToReturn = [FTShelfAudio]();
                annotations.forEach { eachAnnotation in
                    if  let audio = eachAnnotation as? FTAudioAnnotation
                            , let resource = doc.resourceFileItem(eachAnnotation.uuid.appending(".plist")) as? FTFileItemPlist
                            , let info = resource.contentDictionary["recordingModel"] as? Dictionary<String,Any>
                            , let model = FTAudioRecordingModel(dict: info) {
                        let name = audio.audioName
                        let dateAndTime = DateFormatter.localizedString(from: Date(timeIntervalSinceReferenceDate: audio.modifiedTimeInterval), dateStyle: .short, timeStyle: .short)
                        
                        let duration =  FTUtils.timeFormatted(UInt(model.audioDurationWithoutCheckingFileExistance()))
                        
                        let media = FTShelfAudio(audioTitle: name,
                                                 duration: duration,
                                                 page: eachpage.pageIndex,
                                                 document: docItem,
                                                 dateAndTime: dateAndTime)
                        mediaToReturn.append(media)
                    }
                }
                if !mediaToReturn.isEmpty {
                    onMediaFound(mediaToReturn)
                }
            }
        }
    }
}
