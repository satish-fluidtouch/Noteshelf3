//
//  FTShelfItem.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 12/05/22.
//

import Foundation
import MobileCoreServices
import SwiftUI
import FTCommon

enum FTShelfItemType {
    case notebook
    case group
}

let shelfItemURLKey = "shelfItemURL"
let collectionNameKey = "collectionName"
class FTShelfItemViewModel: NSObject, Identifiable, ObservableObject, FTShelfItemCellProgressUpdate {

    var pieProgressView: FTRoundProgressView?
    var statusImageView: UIImageView? // Unused properery, this is just to satisfy protocol `FTShelfItemCellProgressUpdate`
    var shelfItem: FTShelfItemProtocol?
    var progressObserver: NSKeyValueObservation?
    var downloadedStatusObserver: NSKeyValueObservation?
    var uploadingStatusObserver: NSKeyValueObservation?
    var downloadingStatusObserver: NSKeyValueObservation?
    var uploadedStatusObserver: NSKeyValueObservation?
    var animType: FTAnimType = FTAnimType.none;

    var id: String {
        model.uuid
    }
    
    var title: String {
        model.displayTitle
    }
    
    override var hash: Int {
        return self.model.hash;
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let objectB = object as? FTShelfItemViewModel {
            return self.id == objectB.id;
        }
        return false;
    }
    
    var path: String {
        if model.shelfCollection != nil {
            return model.shelfCollection.displayTitle
        }
        return ""
    }

    var longPressOptions: [[FTShelfItemContexualOption]] {
        FTShelfItemContextualMenuOptions(id: id, shelfItem: self,shelfItemCollection: model.shelfCollection).longPressActions
    }
    
    var type: FTShelfItemType {
        return .notebook;
    }

    private(set) var model: FTShelfItemProtocol

    @Published var isBackupOn: Bool = false
    @Published var isNotDownloaded = false
    @Published var isFavorited: Bool = false
    @Published var coverImage = UIImage(named: "defaultNoCover")!
    @Published var isLoadingNotebook: Bool = false
    @Published var isDownloadingNotebook: Bool = false
    @Published var isSelected: Bool = false
    @Published var progress: CGFloat = 0.0
    @Published var uploadDownloadInProgress: Bool = false
    @Published var popoverType: FTNotebookPopoverType?
    @Published var isNS2Book: Bool = false

    init(model: FTShelfItemProtocol) {
        self.model = model
        super.init()
        self.removeObservers()
        self.addObservers()
        //TODO: (AK) can be moved to on demand
        self.fetchCoverImage()
        self.updateDownloadStatusFor(item: model);
        self.isFavorited = FTRecentEntries.isFavorited(model.URL)
        self.isNS2Book = model.URL.isNS2Book
    }
        
    func configureShelfItem(_ item: FTShelfItemProtocol){
        if (nil == self.shelfItem) || (self.shelfItem?.URL != model.URL) {
            self.stopAnimation();
            self.observeDownloadedStatusIfNeeded(forShelfItem: item);
        }
        self.shelfItem = item;
        self.startObservingProgressUpdates()
    }
    
    func didFinishUpdating() {

    }
    
    static func == (lhs: FTShelfItemViewModel, rhs: FTShelfItemViewModel) -> Bool {
        return lhs.isSelected == rhs.isSelected &&
        lhs.isBackupOn == rhs.isBackupOn &&
        lhs.path == rhs.path &&
        lhs.id == rhs.id
    }
    
    // MARK: For Cover Image
    func fetchCoverImage(){
        var token : String?
        token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(self.model, onCompletion: { [weak self](image, imageToken) in
            if token == imageToken, let image {
                self?.coverImage = image
            }
        })
    }
    
    func showLockIcon() -> Bool {
        let isPinEnabledForDoc = self.shelfItem?.URL.isPinEnabledForDocument() ?? false
        if isPinEnabledForDoc {
            return !self.coverImage.isLockedImage()
        }
        return false
    }

    deinit {
        removeObservers()
        removeAllKeyPathObservers()
        stopObservingProgressUpdates()
    }
    
    func notebookShape() -> AnyShape {
        if coverImage.needEqualCorners {
            return AnyShape(RoundedRectangle(cornerRadius:FTShelfItemProperties.Constants.Notebook.landCoverCornerRadius));
        }
        return AnyShape(FTNotebookShape())
    }
}

// MARK: Loader and progress view
extension FTShelfItemViewModel {
    func showLoader(){
        self.isLoadingNotebook = true
    }
    @objc func stopLoader(_ notification : Notification){
        if let item = notification.object as? FTShelfItemProtocol {
            if item.uuid == self.shelfItem?.uuid {
                self.isLoadingNotebook = false
            }
        }
    }
    @objc func makeFavorite(_ notification : Notification){
        if let item = notification.object as? FTShelfItemProtocol {
            if item.uuid == self.shelfItem?.uuid {
                runInMainThread {
                    self.isFavorited = FTRecentEntries.isFavorited(item.URL)
                }
            }
        }
    }
    
    @objc func updateCover(_ notification : Notification){
        if let item = notification.object as? FTShelfItemProtocol {
            if item.uuid == self.shelfItem?.uuid {
                runInMainThread {
                    self.fetchCoverImage()
                }
            }
        }
    }
    func showDownloadingProgressView(){
        self.isDownloadingNotebook = true
        self.isNotDownloaded = false
    }
    func stopDownloadingProgressView(){
        self.isDownloadingNotebook = false
    }
    func prepareNotebookTitleBasedOnGroups(){

    }
}

extension FTShelfItemViewModel {
    private func addObservers(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.stopLoader(_:)), name: Notification.Name.shelfItemRemoveLoader, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.makeFavorite(_:)), name: Notification.Name.shelfItemMakeFavorite, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateCover(_:)), name: Notification.Name.shelfItemUpdateCover, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shelfitemDidgetUpdated(_:)), name: NSNotification.Name.shelfItemUpdated, object: nil)
    }
    
    @objc func shelfitemDidgetUpdated(_ notification: Notification) {
        if let userInfo = notification.userInfo,let items = userInfo[FTShelfItemsKey] as? [FTDocumentItem], let item = items.first, item.uuid == self.model.uuid {
            self.fetchCoverImage()
        }
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .shelfItemRemoveLoader, object: nil)
        NotificationCenter.default.removeObserver(self, name: .shelfItemMakeFavorite, object: nil)
        NotificationCenter.default.removeObserver(self, name: .shelfItemUpdateCover, object: nil)
        NotificationCenter.default.removeObserver(self, name: .shelfItemUpdated, object: nil)
    }
    
    func updateDownloadStatusFor(item : FTShelfItemProtocol) {
        guard let documentItem = item as? FTDocumentItem else {
            return
        }

        self.uploadDownloadInProgress = false;

        if(documentItem.isDownloading) {
            let progress = min(CGFloat(documentItem.downloadProgress)/100,1.0);
            self.animType = .download;
            self.showDownloadingProgressView();
            self.progress = progress;
        }
        else if ((documentItem.isDownloaded)) {
            self.progress = 1.0;
            self.isNotDownloaded = false
            self.stopDownloadingProgressView()
            self.fetchCoverImage()
        }
        else if(documentItem.URL.downloadStatus() == .notDownloaded) {
            self.isNotDownloaded = true
        }
        if documentItem.isUploading {
            self.animType = .upload;
            self.uploadDownloadInProgress = true
        }
    }
}
extension FTShelfItemViewModel {
    //MARK:- isDownloaded

    func removeAllKeyPathObservers()
    {
        self.removeUrlObserversIfNeeded();
    }
    
    private func observeDownloadedStatusIfNeeded(forShelfItem shelfItem: FTShelfItemProtocol) {
        self.removeUrlObserversIfNeeded();
        self.shelfItem = shelfItem;
        self.addUrlObserversIfNeeded()
    }
    private func addUrlObserversIfNeeded(){
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didChangeMetadata(_:)),
                                               name: .didChangeURL,
                                               object: self.shelfItem);
    }

    func removeUrlObserversIfNeeded(){
        if let curShelfItem = self.shelfItem {
            NotificationCenter.default.removeObserver(self,
                                                      name: .didChangeURL,
                                                      object: curShelfItem);
        }
    }

    @objc func didChangeMetadata(_ notification : NSNotification)
    {
        if notification.name == .didChangeURL {
            if let documentItem = notification.object as? FTShelfItemProtocol{
                runInMainThread {
                    self.configureShelfItem(documentItem)
                }
            }
            return;
        }
    }
    @objc func removeLoader(_ notification : Notification) {

        if let item = notification.object as? FTShelfItemProtocol {
            if item.uuid == self.shelfItem?.uuid {
                self.stopLoader(notification)
            }
        }
    }
}
extension FTShelfItemViewModel: NSItemProviderWriting {
    static var writableTypeIdentifiersForItemProvider: [String] {
        return [ kUTTypeData as String]
    }

    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        let progress = Progress(totalUnitCount: 1)
        do {
            let dict = [shelfItemURLKey : self.model.URL.path,
                        collectionNameKey : self.model.shelfCollection.title] as [String : Any];
            let data = try PropertyListSerialization.data(fromPropertyList: dict,
                                                              format: .xml,
                                                              options: 0)
            progress.completedUnitCount = 1
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        return progress
    }
}
