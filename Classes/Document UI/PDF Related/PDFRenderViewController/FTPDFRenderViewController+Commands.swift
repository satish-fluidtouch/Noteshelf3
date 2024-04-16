//
//  FTPDFRenderViewController+Commands.swift
//  Noteshelf3
//
//  Created by Narayana on 25/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

protocol FTShortcutActions: AnyObject {
    // Shortcuts
    func addPage()
    func rotatePage(angle: UInt)
    func bookMarkAction(page: FTThumbnailable)
    func deletePageAction(page: FTThumbnailable)
    func duplicateAction(pages: [FTThumbnailable], onCompletion: (()->())?)
    func handleTagPage(source: Any, controller: UIViewController, pages: NSSet)
    func cameraAction()
    func scrollingAction(direction: Int)

    // Media
    func photoAction()
    func audioAction()
    func unsplashAction(source: Any)
    func pixabayAction(source: Any)
    func emojiAction(source: Any)
    func stickersAction(source: Any)
    func savedClipsAction(source: Any)

    // Share
    func shareNotebookAsPDF(source: Any)
    func sharePageAsPng(source: Any)
    func savePageAsPhoto()
}

enum FTCommand: Equatable {
    // Media
    case audio
    case photo
    case unsplash(source: Any)
    case pixabay(source: Any)
    case emojis(source: Any)
    case stickers(source: Any)
    case savedClips(source: Any)

    // Shortcuts
    case addPage
    case rotatePage(angle: UInt)
    case bookmark(page: FTThumbnailable)
    case deletePage(page: FTThumbnailable)
    case duplicatePage(pages: [FTThumbnailable])
    case tag(source: Any, controller: UIViewController, pages: NSSet)
    case camera
    case scrolling(direction: Int)

    // Share
    case shareNoteBookAsPDF(source: Any)
    case sharePageAsPng(source: Any)
    case savePageAsPhoto

    static func == (lhs: FTCommand, rhs: FTCommand) -> Bool {
        return false
    }
}

protocol FTShortcutCommand: AnyObject {
    func execute(type: FTCommand, onCompletion: (()->())?)
}

class FTShortcutExecuter: FTShortcutCommand {
    private weak var receiver: FTShortcutActions?

   init(receiver: FTShortcutActions) {
        self.receiver = receiver
    }

    func execute(type: FTCommand, onCompletion: (()->())? = nil) {
        switch type {
        case .addPage:
            self.receiver?.addPage()

        case .rotatePage(let value):
            self.receiver?.rotatePage(angle: value)

        case .bookmark(let page):
            self.receiver?.bookMarkAction(page: page)

        case .deletePage(let page):
            self.receiver?.deletePageAction(page: page)

        case .duplicatePage(let pages):
            self.receiver?.duplicateAction(pages: pages, onCompletion: onCompletion)

        case .tag(let source, let controller, let pages):
            self.receiver?.handleTagPage(source: source, controller: controller, pages: pages)
            
        case .camera:
            self.receiver?.cameraAction()
            
        case .scrolling(let source):
            self.receiver?.scrollingAction(direction: source)
            
            // Media
        case .photo:
            self.receiver?.photoAction()

        case .audio:
            self.receiver?.audioAction()

        case .unsplash(let source):
            self.receiver?.unsplashAction(source: source)

        case .pixabay(let source):
            self.receiver?.pixabayAction(source: source)

        case .emojis(let source):
            self.receiver?.emojiAction(source: source)

        case .savedClips(let source):
            self.receiver?.savedClipsAction(source: source)

        case .stickers(let source):
            self.receiver?.stickersAction(source: source)

            // Share
        case .shareNoteBookAsPDF(let source):
            self.receiver?.shareNotebookAsPDF(source: source)

        case .sharePageAsPng(let source):
            self.receiver?.sharePageAsPng(source: source)

        case .savePageAsPhoto:
            self.receiver?.savePageAsPhoto()

        default:
            break
        }
    }
}

extension FTPDFRenderViewController: FTShortcutActions {
    @objc func configureShortcutActions() {
        self.executer = FTShortcutExecuter(receiver: self)
    }

    func addPage() {
        let curPageIndex = self.getNewPageInsertIndex()
        self.insertEmptyPage(at: curPageIndex)
    }

    func rotatePage(angle: UInt) {
        guard let curPage = self.currentlyVisiblePage() else {
            return
        }
        curPage.rotate(by:angle)
        NotificationCenter.default.post(name: NSNotification.Name.FTPageDidChangePageTemplate,
                                        object: curPage)
    }

    func bookMarkAction(page: FTThumbnailable) {
        let isBookmarked = !page.isBookmarked
        page.isBookmarked = isBookmarked
        if(isBookmarked == false){
            page.bookmarkTitle = ""
            page.bookmarkColor = ""
        }
        else{
            page.bookmarkTitle = ""
            page.bookmarkColor = "C69C3C"
        }
        (page as? FTNoteshelfPage)?.isDirty = true
        NotificationCenter.default.post(name: .shouldReloadFinderNotification, object: nil)
    }

    func deletePageAction(page: FTThumbnailable) {
        guard let doc = self.pdfDocument else { return }
        let isPinEnabled = doc.isPinEnabled()
        let alert = UIAlertController(title: "", message: "", preferredStyle: UIAlertController.Style.alert)
        let cancelAction = UIAlertAction(title: "Cancel".localized, style: (isPinEnabled ? .destructive : .cancel), handler: nil)

        let moveToTrashAction = UIAlertAction(title: "MoveToTrash".localized, style: (isPinEnabled ? .default : .destructive), handler: { [weak self] action in
            if let document = doc as? FTThumbnailableCollection, document.documentPages().count == 1 {
                doc.insertPageAtIndex(1)
            }
            self?.movePagestoTrash(from: doc, pages: [page]) { [weak self] (error, _) in
                if error == nil, let weakSelf = self, let document = doc as? FTThumbnailableCollection {
                    weakSelf.deletePagesPermanantly(from: document,
                                                    pages: [page])
                }
            }
        })

        if isPinEnabled {
            alert.message = "DeletePagePasswordProtectedAlert".localized
            // let delete Permanently Action
            let deletePermanentAction = UIAlertAction(title: "DeletePermanently".localized, style: .default,  handler: { [weak self] (action) in
                if let document = doc as? FTThumbnailableCollection, document.documentPages().count == 1 {
                    doc.insertPageAtIndex(1)
                }
                if let weakSelf = self, let document = doc as? FTThumbnailableCollection {
                    weakSelf.deletePagesPermanantly(from: document,
                                                    pages: [page])
                }
            })
            alert.addAction(deletePermanentAction)
            alert.addAction(moveToTrashAction)
            alert.addAction(cancelAction)
        } else {
            alert.title = String(format: "customizeToolbar.deletePageConfirmation".localized, page.pageIndex() + 1)
            alert.addAction(cancelAction)
            alert.addAction(moveToTrashAction)
        }
        self.present(alert, animated: true, completion: nil)
    }

    func duplicateAction(pages: [FTThumbnailable], onCompletion: (()->())?) {
        _ = (self.pdfDocument as? FTThumbnailableCollection)?.duplicatePages(pages, onCompletion: { copiedPages in
            onCompletion?()
        })
    }

    func handleTagPage(source: Any, controller: UIViewController, pages: NSSet) {
        if self.pdfDocument is FTThumbnailableCollection {
            let tags = FTCacheTagsProcessor.shared.commonTagsFor(pages: pages)
            let tagItems = FTTagsProvider.shared.getAllTagItemsFor(tags)
            FTTagsViewController.showTagsController(fromSourceView: source, onController: controller, tags: tagItems)
        }
    }
    
    func cameraAction() {
        FTImagePicker.shared.showImagePickerController(from: self)
    }
    
    func scrollingAction(direction: Int) {
        if let directionFlow = FTPageLayout(rawValue:direction) {
            UserDefaults.standard.pageLayoutType = directionFlow
        }
    }

    // Media
    func photoAction() {
        self.insertingPhotoAsPage = false
        FTPHPicker.shared.presentPhPickerController(from: self)
    }

    func audioAction() {
        self.audioButtonAction()
    } 
    func unsplashAction(source: Any) {
        FTMediaLibraryViewController.showAddMenuPixaBayController(from: self, mediaType: .unSplash, source: source)
    }

    func pixabayAction(source: Any) {
        FTMediaLibraryViewController.showAddMenuPixaBayController(from: self, mediaType: .pixabay, source: source)
    }

    func emojiAction(source: Any) {
        FTEmojisViewController.showAsPopover(fromSourceView: source, overViewController: self, withDelegate: self, toHideBackBtn: true)
    }

    func savedClipsAction(source: Any) {
        FTSavedClipsViewController.showSavedClipsController(from: self, source: source, delegate: self, toHideBackBtn: true)
    }
    
    func stickersAction(source: Any) {
        let model = FTStickerCategoriesViewModel(delegate: self)
        var view = FTStickerCategoriesView(model: model, downloadedViewModel: FTDownloadedStickerViewModel())
        view.toHideBackButton = true
        let stickerVc = FTStickersViewController(rootView: view)
        stickerVc.view.backgroundColor = UIColor.appColor(.popoverBgColor)
        let navVc = UINavigationController(rootViewController: stickerVc)
        navVc.isNavigationBarHidden = true
        stickerVc.ftPresentationDelegate.source = source as AnyObject
        self.ftPresentPopover(vcToPresent: navVc, contentSize: CGSize(width: 320.0, height: 544.0), hideNavBar: true)
    }

    func sharePageAsPng(source: Any) {
        if let shelfItem = shelfItemManagedObject.documentItem as? FTShelfItemProtocol {
            var pages: [FTPageProtocol] = []
            if let currentPage = self.currentlyVisiblePage() {
                pages.append(currentPage)
            }
            let shareCoord = FTShareCoordinator(shelfItems: [shelfItem], pages: pages, presentingController: self, sourceView: source)
            let properties = FTExportProperties()
            properties.exportFormat = kExportFormatImage
            shareCoord.beginShare(properties, option: .currentPage, type: .share)
        }
    }

    func shareNotebookAsPDF(source: Any) {
        if let shelfItem = shelfItemManagedObject.documentItem as? FTShelfItemProtocol {
            let shareCoord = FTShareCoordinator(shelfItems: [shelfItem], presentingController: self, sourceView: source)
            let properties = FTExportProperties()
            properties.exportFormat = kExportFormatPDF
            shareCoord.beginShare(properties, option: .notebook,type: .share)
        }
    }

    func savePageAsPhoto() {
        let coordinator = self.getShareInfo(using: .currentPage)
        let properties = FTExportProperties()
        properties.exportFormat = kExportFormatImage
        coordinator?.beginShare(properties, option: .currentPage,type: .savetoCameraRoll)
    }
}

// MARK: Delete page helper functions
extension FTPDFRenderViewController {
    internal func movePagestoTrash(from doc:FTDocumentProtocol,  pages: NSSet, completion: @escaping (Error?, FTShelfItemProtocol?) -> ()) {
        let copiedPages = pages.allObjects as! [FTPageProtocol]
        let pagesToCopy = copiedPages.sorted(by: { (p1, p2) -> Bool in
            return (p1.pageIndex() < p2.pageIndex())
        })

        let info = FTDocumentInputInfo()
        info.rootViewController = self
        info.overlayStyle = FTCoverStyle.clearWhite
        info.coverTemplateImage = FTPDFExportView.snapshot(forPage: pagesToCopy[0],
                                                           size: portraitCoverSize,
                                                           screenScale: 2.0,
                                                           shouldRenderBackground: true)
        info.isNewBook = true
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(FTUtils.getUUID())
        _ = doc.createDocumentAtTemporaryURL(url,
                                             purpose: .trashRecovery,
                                             fromPages: pagesToCopy,
                                             documentInfo: info)
        { (_, error) in
            if(nil == error) {
                let title = doc.URL.deletingPathExtension().lastPathComponent;
                FTNoteshelfDocumentProvider.shared.addDocumentAtURLToTrash(url,
                                                                           title: title)
                { (error, shelfItem) in
                    completion(error, shelfItem)
                }
            } else {
                completion(error, nil)
            }
        }
    }

    internal func deletePagesPermanantly(from document: FTThumbnailableCollection, pages: NSSet) {
        DispatchQueue.main.async {
            document.deletePages(Array(pages) as! [FTThumbnailable])
            document.saveDocument(completionHandler: { [weak self] (_) in
                NotificationCenter.default.post(name: .shouldReloadFinderNotification, object: nil)
            })
        }
    }
}

extension FTPDFRenderViewController: FTStickerdelegate {
    public func didTapSticker(with image:UIImage, title: String) {
        self.insert([image], center: .zero, droppedPoint: .zero, source: FTInsertImageSourceSticker)
        self.dismiss()
    }

    public func dismiss() {
        self.dismiss(animated: true)
    }
}

class FTPhotoSaver: NSObject {
    var imageSaveCompletionHandler: InternalCompletionHandler?

    func writeToPhotoAlbum(image: UIImage, completion: @escaping InternalCompletionHandler) {
        let selector = #selector(handleImageSaved(_:didFinishSavingWithError:contextInfo:))
        UIImageWriteToSavedPhotosAlbum(image, self, selector, nil)
        self.imageSaveCompletionHandler = completion
    }

    @objc func handleImageSaved(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer?) {
        if let error = error {
            // Handle error
            imageSaveCompletionHandler?(FTExportItem(), error, false)
        } else {
            // Success
            imageSaveCompletionHandler?(FTExportItem(), nil, true)
        }
        self.imageSaveCompletionHandler = nil
    }
}
