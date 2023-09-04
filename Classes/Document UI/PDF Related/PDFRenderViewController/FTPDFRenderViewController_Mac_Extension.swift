//
//  FTPDFRenderViewController_Mac_Extension.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 03/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

#if targetEnvironment(macCatalyst)
extension FTPDFRenderViewController {
    func didTapCenterToolButton(_ buttonType: FTDeskCenterPanelTool, toolbarItem: NSToolbarItem) {
        FTQuickPageNavigatorViewController.hidePageNavigator(forController: self)
        FTRefreshViewController.addObserversForHideNewPageOptions()
        switch buttonType {
        case .pen:
            self.switchMode(.deskModePen, toolbarItem: toolbarItem)

        case .highlighter:
            self.switchMode(.deskModeMarker, toolbarItem: toolbarItem)

        case .eraser:
            self.switchMode(.deskModeEraser, toolbarItem: toolbarItem)

        case .shapes:
            self.switchMode(.deskModeShape, toolbarItem: toolbarItem)

        case .textMode:
            self.switchMode(.deskModeText, toolbarItem: toolbarItem)

        case .presenter:
            self.readOnlyModeisOn = false
            self.switchMode(.deskModeLaser, toolbarItem: toolbarItem)

        case .openAI:
            self.firstPageController()?.startOpenAiForPage();
            
        case .lasso:
            self.switchMode(.deskModeClipboard, toolbarItem: toolbarItem)

        case .photo:
            self.executer?.execute(type: .photo)

        case .audio:
            self.executer?.execute(type: .audio)

        case .rotatePage:
            self.executer.execute(type: .rotatePage(angle: FTPageRotation.nintetyClockwise.rawValue))
            self.finderNotifier?.didRotatePage()
            let config = FTToastConfiguration(title: "shortcut.toast.rotatePage".localized)
            FTToastHostController.showToast(from: self, toastConfig: config)

        case .bookmark:
            if let currentPage = self.currentlyVisiblePage() as? FTThumbnailable {
                self.executer.execute(type: .bookmark(page: currentPage))
                self.finderNotifier?.didBookmarkPage()
                let title: String
                if currentPage.isBookmarked {
                    title = "shortcut.toast.bookmarkPage".localized
                } else {
                    title = "shortcut.toast.removePageFromBookmarks".localized
                }
                let config = FTToastConfiguration(title: title)
                FTToastHostController.showToast(from: self, toastConfig: config)
            }

        case .page:
            self.executer.execute(type: .addPage)
            self.finderNotifier?.didAddPage()
            let config = FTToastConfiguration(title: "shortcut.toast.addPage".localized)
            FTToastHostController.showToast(from: self, toastConfig: config)

        case .duplicatePage:
            if let page = self.firstPageController()?.pdfPage as? FTThumbnailable {
                self.executer.execute(type: .duplicatePage(pages: [page])) {
                    self.finderNotifier?.didDuplicatePage()
                    let config = FTToastConfiguration(title: "shortcut.toast.duplicatePage".localized)
                    FTToastHostController.showToast(from: self, toastConfig: config)
                }
            }

        case .tag:
            if let page = self.firstPageController()?.pdfPage as? FTThumbnailable {
                let pagesSet = NSSet(array: [page])
                self.executer.execute(type: .tag(source: toolbarItem, controller: self, pages: pagesSet))
            }
        case .unsplash:
            self.executer.execute(type: .unsplash(source: toolbarItem))

        case .pixabay:
            self.executer.execute(type: .pixabay(source: toolbarItem))

        case .emojis:
            self.executer.execute(type: .emojis(source: toolbarItem))

        case .stickers:
            self.executer.execute(type: .stickers(source: toolbarItem))
            
        case .zoomBox:
            self.zoomButtonAction()

        case .hand:
            self.readOnlyButtonAction()

        case .share:
            self.showShareOptions(with: toolbarItem)

        case .shareNotebookAsPDF:
            self.executer.execute(type: .shareNoteBookAsPDF)

        case .sharePageAsPng:
            self.executer.execute(type: .sharePageAsPng)

        case .savePageAsPhoto:
            self.executer.execute(type: .savePageAsPhoto) {
                    let config = FTToastConfiguration(title: "shortcut.toast.savePageAsPhoto".localized)
                    FTToastHostController.showToast(from: self, toastConfig: config)
            }

        default:
            break
        }
    }
    
    private func switchMode(_ mode:RKDeskMode,toolbarItem: NSToolbarItem) {
        if(self.currentDeskMode == mode) {
            self.openMacPenRack(mode: mode, toolbarItem: toolbarItem);
        }
        else {
            self.switch(mode, sourceView: nil);
        }
    }
        
    private func openMacPenRack(mode:RKDeskMode,toolbarItem: NSToolbarItem) {
        self.normalizeAndEndEditingAnnotation(true);
        let activity = self.view.window?.windowScene?.userActivity;        
        switch(mode) {
        case .deskModePen:
            FTPenRackViewController.setRackType(penTypeRack: FTRackData(type: .pen, userActivity: activity))
            FTPenRackViewController.showPopOver(presentingController: self, sourceView: toolbarItem)
            self.normalizeAndEndEditingAnnotation(true);
        case .deskModeMarker:
            FTPenRackViewController.setRackType(penTypeRack: FTRackData(type: .highlighter, userActivity: activity))
            FTPenRackViewController.showPopOver(presentingController: self, sourceView: toolbarItem)
            self.normalizeAndEndEditingAnnotation(true);
        case .deskModeEraser:
            FTEraserRackViewController.setRackType(penTypeRack: FTRackData(type: .eraser, userActivity: activity))
            let eraserVc = FTEraserRackViewController.showPopOver(presentingController: self, sourceView: toolbarItem)
            (eraserVc as? FTEraserRackViewController)?.eraserDelegate = self
        case .deskModeShape:
            FTShapesRackViewController.setRackType(penTypeRack: FTRackData(type: .shape, userActivity: activity))
            FTShapesRackViewController.showPopOver(presentingController: self, sourceView: toolbarItem)
        case .deskModeClipboard:
            FTLassoRackViewController.showPopOver(presentingController: self
                                                , sourceView: toolbarItem);
        default:
            break;
        }
    }
    
    func toolbar(_ toolbar: NSToolbar, didTapOnMenuitem menuItem: UIAction.Identifier?) {
        guard let menuItemID = menuItem else {
            return;
        }
        switch(menuItemID) {
        case FTNotebookSidebarMenuType.showDocumentOnly.menuIdentifier:
            if(self.noteBookSplitViewController()?.displayMode == .oneBesideSecondary) {
                self.toggleFinder(true);
            }
        case FTNotebookSidebarMenuType.thumbnails.menuIdentifier:
            if(self.noteBookSplitViewController()?.displayMode == .secondaryOnly) {
                self.toggleFinder(true);
            }
            showFinderContent(FTNotebookSidebarMenuType.thumbnails);
        case FTNotebookSidebarMenuType.bookmarks.menuIdentifier:
            if(self.noteBookSplitViewController()?.displayMode == .secondaryOnly) {
                self.toggleFinder(true);
            }
            showFinderContent(FTNotebookSidebarMenuType.bookmarks);
        case FTNotebookSidebarMenuType.mediaContent.menuIdentifier:
            if(self.noteBookSplitViewController()?.displayMode == .secondaryOnly) {
                self.toggleFinder(true);
            }
            showFinderContent(FTNotebookSidebarMenuType.mediaContent);
        case FTNotebookSidebarMenuType.tableOfContents.menuIdentifier:
            if(self.noteBookSplitViewController()?.displayMode == .secondaryOnly) {
                self.toggleFinder(true);
            }
            showFinderContent(FTNotebookSidebarMenuType.tableOfContents);
        case FTNotebookSidebarMenuType.search.menuIdentifier:
            if(self.noteBookSplitViewController()?.displayMode == .secondaryOnly) {
                self.toggleFinder(true);
            }
            showFinderContent(FTNotebookSidebarMenuType.search);
        default:
            break;
        }
    }
    
    private func showFinderContent(_ item: FTNotebookSidebarMenuType) {
        guard let finderTabHostController = self.noteBookSplitViewController()?.viewController(for: .primary) as? FTFinderTabHostingController
        ,let finderTabController = finderTabHostController.getChild() else {
            return;
        }
        finderTabController.showFinderContent(item);
    }
}

extension FTPDFRenderViewController: FTMenuActionResponder {
    
    func canPeformAction(action: Selector) -> Bool {
        var canPerform = false;
        if action == #selector(importDocumentFromFinderClicked(_:))
            || action == #selector(FTMenuActionResponder.zoomInClicked(_:))
            || action == #selector(FTMenuActionResponder.zoomOutClicked(_:))
            || action == #selector(FTMenuActionResponder.actualSizeClicked(_:))
            || action == #selector(FTMenuActionResponder.newPageClicked(_:))
            || action == #selector(FTMenuActionResponder.pageFromTemplateClicked(_:))
            || action == #selector(FTMenuActionResponder.audioClicked(_:))
            || action == #selector(FTMenuActionResponder.importMedia(_:))
            || action == #selector(FTMenuActionResponder.insertWebClip(_:))
        {
            canPerform = true
        }
        else if action == #selector(navigateToPreviousPage(_:)) ||
                    action == #selector(navigateToFirstPage(_:))
        {
            if let pageIndex = self.firstPageController()?.pdfPage?.pageIndex(){
                canPerform = (pageIndex > 0)
            }
        }
        else if action == #selector(navigateToNextPage(_:)) ||
                    action == #selector(navigateToLastPage(_:))
        {
            if let pageIndex = self.firstPageController()?.pdfPage?.pageIndex(){
                canPerform = (pageIndex < self.pdfDocument.pages().count - 1)
            }
        }
        return canPerform;
    }
    
    //MARK:- Zoom Menu
    @objc func zoomInClicked(_ sender: AnyObject?) {
        if let currentPageVC = self.firstPageController() {
            if UserDefaults.standard.pageLayoutType == .vertical {
                if let scrView = currentPageVC.delegate?.mainScrollView {
                    scrView.isProgramaticallyZooming = true
                    scrView.zoom(scrView.zoomFactor + 1, animate: true, completionBlock: nil)
                }
            }
            else {
                if let scrView = currentPageVC.scrollView {
                    currentPageVC.zoom(scale: scrView.zoom + 1,
                                       animate: true,
                                       completionBlock: nil);
                }
            }
        }
    }
    
    @objc func zoomOutClicked(_ sender: AnyObject?) {
        if let currentPageVC = self.firstPageController() {
            if UserDefaults.standard.pageLayoutType == .vertical {
                if let scrView = currentPageVC.delegate?.mainScrollView {
                    scrView.isProgramaticallyZooming = true
                    scrView.zoom(scrView.zoomFactor - 1, animate: true, completionBlock: nil)
                }
            }
            else {
                if let scrView = currentPageVC.scrollView {
                    currentPageVC.zoom(scale: scrView.zoom - 1,
                                       animate: true,
                                       completionBlock: nil);
                }
            }
        }
    }
    
    @objc func actualSizeClicked(_ sender: AnyObject?) {
        if let currentPageVC = self.firstPageController() {
            if UserDefaults.standard.pageLayoutType == .vertical {
                if let scrView = currentPageVC.delegate?.mainScrollView {
                    scrView.isProgramaticallyZooming = true
                    scrView.zoom(1, animate: true, completionBlock: nil)
                }
            }
            else {
                currentPageVC.zoom(scale: 1,
                                   animate: true,
                                   completionBlock: nil);
            }
        }
    }
        
    @objc func navigateToNextPage(_ sender: AnyObject?) {
        if let pageIndex = self.firstPageController()?.pdfPage?.pageIndex(){
            self.showPage(at: min(self.pdfDocument.pages().count - 1, pageIndex + 1), forceReLayout: false)
        }
    }
    
    @objc func navigateToPreviousPage(_ sender: AnyObject?) {
        if let pageIndex = self.firstPageController()?.pdfPage?.pageIndex(){
            self.showPage(at: max(0, pageIndex - 1), forceReLayout: false)
        }
    }
    
    @objc func navigateToFirstPage(_ sender: AnyObject?) {
        self.showPage(at: 0, forceReLayout: false)
    }
    
    @objc func navigateToLastPage(_ sender: AnyObject?) {
        self.showPage(at: self.pdfDocument.pages().count - 1, forceReLayout: false)
    }
    
    @objc  func newPageClicked(_ sender: AnyObject?) {
        didTapPage(.newPage);
    }
    
    @objc func pageFromTemplateClicked(_ sender: AnyObject?) {
        didTapPage(.chooseTemplate);
    }
    
    @objc func importDocumentFromFinderClicked(_ sender: AnyObject?) {
        didTapPage(.importDocument);
    }
    
    @objc func audioClicked(_ sender: AnyObject?) {
        didTapMedia(.audio);
    }
    
    @objc func importMedia(_ sender: AnyObject?) {
        didTapMedia(.importMedia);
    }
    
    @objc func insertWebClip(_ sender: AnyObject?) {
        didTapAttachment(.webClip);
    }
}
#endif
