//
//  FTShelfItemModel.swift
//  Noteshelf3
//
//  Created by Akshay on 20/05/22.
//

import Foundation

enum ShelfItemType {
    case collection
    case group
    case notebook
}
class FTShelfItems: ObservableObject,Identifiable {

    var id: String
    var title: String
    var subTitle: String?
    var shelfItemType: ShelfItemType = .collection
    var collection: FTShelfItemCollection?
    var group: FTGroupItemProtocol?
    var notebook: FTShelfItemProtocol?
    @Published var coverImage: UIImage? = UIImage(named: "covergray")

    init(collection: FTShelfItemCollection) {
        self.id = collection.uuid
        self.title = collection.displayTitle
        self.shelfItemType = .collection
        self.collection = collection
    }
}

class FTShelfGroupItem: FTShelfItems {

    var groupCoverViewModel: FTGroupCoverViewModel = FTGroupCoverViewModel()

    init(group: FTGroupItemProtocol) {
        super.init(collection: group.shelfCollection)
        self.id = group.uuid
        self.title = group.displayTitle
        self.shelfItemType = .group
        self.group = group
        self.subTitle = "\(group.childrens.count)" + (group.childrens.count > 1 ? " items" : " item")
    }
}
class FTShelfNotebookItem: FTShelfItems {
    private var progressObserver: NSKeyValueObservation?
    private var downloadedStatusObserver: NSKeyValueObservation?
    private var downloadingStatusObserver: NSKeyValueObservation?

    @Published var notDownloaded = false
    @Published var isDownloadingNotebook: Bool = false
    @Published var progress: CGFloat = 0.0

    init(notebook: FTShelfItemProtocol) {
        super.init(collection: notebook.shelfCollection)
            self.id = notebook.uuid
            self.title = notebook.displayTitle
            self.shelfItemType = .notebook
            self.notebook = notebook
            self.collection = notebook.shelfCollection
            self.group = notebook.parent
            self.subTitle = notebook.fileModificationDate.shelfShortStyleFormat()
            self.updateDownloadStatusFor(item: notebook)
    }

    deinit {
        self.stopObservingProgressUpdates()
    }

     func downloadNotebook() {
        guard let book = notebook else {
            return
        }
        do {
            if(CloudBookDownloadDebuggerLog) {
                FTCLSLog("Book: \(book.displayTitle): Download Requested")
            }
            try FileManager().startDownloadingUbiquitousItem(at: book.URL)
            self.startObservingProgressUpdates()
        }
        catch let nserror as NSError {
            FTCLSLog("Book: \(book.displayTitle): Download Failed :\(nserror.description)")
            FTLogError("Notebook download failed", attributes: nserror.userInfo)
        }
    }

    func startObservingProgressUpdates(){
        self.stopObservingProgressUpdates()
        self.progressObserver = (self.notebook as? FTDocumentItem)?.observe(\.downloadProgress,
                                                                              options: [.new, .old]) { [weak self] (shelfItem, _) in
            runInMainThread {
                self?.updateDownloadStatusFor(item: shelfItem)
            }
        }
        self.downloadingStatusObserver = (self.notebook as? FTDocumentItem)?.observe(\.isDownloading,
                                                                                       options: [.new, .old]) { [weak self] (shelfItem, _) in
            runInMainThread {
                self?.updateDownloadStatusFor(item: shelfItem)
            }
        }
        self.downloadedStatusObserver = (self.notebook as? FTDocumentItem)?.observe(\.downloaded,
                                                                                      options: [.new, .old]) { [weak self] (shelfItem, _) in
            runInMainThread {
                self?.updateDownloadStatusFor(item: shelfItem)
            }
        }
    }

    func updateDownloadStatusFor(item : FTShelfItemProtocol) {
        guard let documentItem = item as? FTDocumentItem else {
            return
        }
        self.isDownloadingNotebook = false

        if documentItem.isDownloaded {
            self.notDownloaded = false
            self.progress = 1.0
        } else if documentItem.isDownloading {
            let progress = min(CGFloat(documentItem.downloadProgress)/100,1.0)
            self.isDownloadingNotebook = true
            self.notDownloaded = false
            self.progress = progress
        } else if !documentItem.isDownloaded {
            self.notDownloaded = true
        }
    }

    func stopObservingProgressUpdates() {
        self.progressObserver?.invalidate()
        self.downloadedStatusObserver?.invalidate()
        self.downloadingStatusObserver?.invalidate()
    }

    func fetchCoverImage(completionhandler: @escaping (UIImage?) -> ()){
        var token : String?
        if let shelfItemProtocol = notebook {
            token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(shelfItemProtocol, onCompletion: { [weak self](image, imageToken) in
                if token == imageToken {
                    self?.coverImage = (nil == image ? UIImage.shelfDefaultNoCoverImage : image)
                    completionhandler(self?.coverImage)
                }
            })
        }
    }
}
