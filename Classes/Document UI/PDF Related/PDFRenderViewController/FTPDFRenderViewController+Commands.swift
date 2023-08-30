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
    func duplicateAction(pages: [FTThumbnailable], onCompletion: (()->())?)
    func handleTagPage(source: Any, controller: UIViewController, pages: NSSet)

    // Media
    func photoAction()
    func audioAction()
    func unsplashAction(source: Any)
    func pixabayAction(source: Any)
    func emojiAction(source: Any)
    func stickersAction(source: Any)

    // Share
    func shareNotebookAsPDF()
    func sharePageAsPng()
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

    // Shortcuts
    case addPage
    case rotatePage(angle: UInt)
    case bookmark(page: FTThumbnailable)
    case duplicatePage(pages: [FTThumbnailable])
    case tag(source: Any, controller: UIViewController, pages: NSSet)

    // Share
    case shareNoteBookAsPDF
    case sharePageAsPng
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

        case .duplicatePage(let pages):
            self.receiver?.duplicateAction(pages: pages, onCompletion: onCompletion)

        case .tag(let source, let controller, let pages):
            self.receiver?.handleTagPage(source: source, controller: controller, pages: pages)

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

        case .stickers(let source):
            self.receiver?.stickersAction(source: source)

            // Share
        case .shareNoteBookAsPDF:
            self.receiver?.shareNotebookAsPDF()

        case .sharePageAsPng:
            self.receiver?.sharePageAsPng()

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

    func duplicateAction(pages: [FTThumbnailable], onCompletion: (()->())?) {
        _ = (self.pdfDocument as? FTThumbnailableCollection)?.duplicatePages(pages, onCompletion: { copiedPages in
            onCompletion?()
        })
    }

    func handleTagPage(source: Any, controller: UIViewController, pages: NSSet) {
        if self.pdfDocument is FTThumbnailableCollection {
            let tags = FTCacheTagsProcessor.shared.tagsFor(pages)
            let sortedArray = FTCacheTagsProcessor.shared.tagsModelForTags(tags: tags)
            FTTagsViewController.showTagsController(fromSourceView: source, onController: controller, tags: sortedArray)
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

    func sharePageAsPng() {
        if let source = self.centerPanelToolbarSource(for: .sharePageAsPng), let shelfItem = shelfItemManagedObject.documentItem as? FTShelfItemProtocol {
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

    func shareNotebookAsPDF() {
        if let source = self.centerPanelToolbarSource(for: .shareNotebookAsPDF), let shelfItem = shelfItemManagedObject.documentItem as? FTShelfItemProtocol {
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

extension FTPDFRenderViewController: FTStickerdelegate {
    public func didTapSticker(with image:UIImage) {
        self.insert([image], center: .zero, droppedPoint: .zero, source: FTInsertImageSourceSticker)
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
