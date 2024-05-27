//
//  FTPDFRenderViewController+Finder.swift
//  Noteshelf
//
//  Created by Siva on 09/01/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

extension FTPDFRenderViewController: FTFinderThumbnailsActionDelegate {
     
    //Share
    @objc func toggleFinder(_ animated: Bool) {
        if let splitView = self.noteBookSplitViewController() {
            if splitView.isRegularClass() {
                if self.shouldStartFinderWithFullScreen() {
                    self.presentFinder()
                } else {
                    var displayMode = splitView.displayMode
                    if splitView.displayMode == .secondaryOnly {
                        splitView.preferredSplitBehavior = !UIDevice.isLandscapeOrientation ? .displace : .automatic
                        displayMode = .oneBesideSecondary
                        splitView.curentPrefrredDisplayMode = .oneBesideSecondary
                        FTFinderEventTracker.trackFinderEvent(with: "toolbar_finder_open")
                    } else {
                        splitView.preferredSplitBehavior = .automatic
                        displayMode = .secondaryOnly
                        splitView.curentPrefrredDisplayMode = .secondaryOnly
                        FTFinderEventTracker.trackFinderEvent(with: "toolbar_finder_close")
                    }
                    UIView.animate(withDuration: 0.2) {
                        splitView.preferredDisplayMode = displayMode
                    }
                }
            } else {
                if let finderHostingVc = splitView.viewController(for: .supplementary) as? FTFinderTabHostingController, !finderHostingVc.children.isEmpty, let finderTabVc = finderHostingVc.getChild() {
                    finderTabVc.splitVc = splitView
                    finderTabVc.screenMode = .normal
                    finderTabVc.customTransitioningDelegate = FTCustomTransitionDelegate(with: .interaction, supportsFullScreen: true)
                    self.ftPresentModally(finderTabVc,contentSize: finderHostingVc.view.frame.size, animated: true, completion: nil)
                }
            }
            NotificationCenter.default.post(name: .validationFinderButtonNotification, object: self.view.window)
        }
    }
    
    private func presentFinder() {
        if  let splitView = self.noteBookSplitViewController() ,let finderHostingVc = splitView.viewController(for: .supplementary) as? FTFinderTabHostingController, !finderHostingVc.children.isEmpty, let tabBarVac = finderHostingVc.getChild() {
            tabBarVac.presentFinder()
        }
    }
    
    private func shouldStartFinderWithFullScreen() -> Bool {
        var shouldStartFullScreen = false
        if  let splitView = self.noteBookSplitViewController() ,let finderHostingVc = splitView.viewController(for: .supplementary) as? FTFinderTabHostingController, !finderHostingVc.children.isEmpty, let presentable = finderHostingVc.getChild() as? FTFinderPresentable {
            shouldStartFullScreen = presentable.shouldStartWithFullScreen()
        }
        return shouldStartFullScreen
    }

    
    //MARK:- FTThumbnailableCollectionDelegate
    func currentShelfItemInShelfItemsViewController() -> FTShelfItemProtocol? {
        return self.shelfItemManagedObject.shelfItemProtocol;
    }
    
    func currentGroupShelfItemInShelfItemsViewController() -> FTGroupItemProtocol? {
        return self.shelfItemManagedObject.parent;
    }
    
    func currentShelfItemCollectionInShelfItemsViewController() -> FTShelfItemCollection? {
        return self.shelfItemManagedObject.shelfCollection;
    }
    
    func currentPage(in finderViewController: FTFinderViewController) -> FTThumbnailable? {
        return self.currentlyVisiblePage() as? FTThumbnailable
    }
    
    //    //MARK:- FTThumbnailShareViewControllerDelegate
    //    func finderViewController(_ finderViewController: FTFinderViewController, didSelectPages pages: NSSet) {
    //        finderViewController.dismiss(animated: true, completion: {
    //            runInMainThread {
    //                self.showTargets();
    //            };
    //        });
    //    }
    
    //MARK:- FTThumbnailPickerViewControllerDelegate
    func finderViewController(didSelectPageAtIndex index: Int) {
        self.view.accessibilityElementsHidden = true;
        //finderViewController.dismiss(animated: true, completion: {
            self.showPage(at: index,forceReLayout: false);
            if let currentPageVC = self.firstPageController() {
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: currentPageVC.view);
                runInMainThread {
                    self.view.accessibilityElementsHidden = false;
                }
            }
        //});
    }
    
    func cancelFinderSearchOperation() {
        self.cancelSearchOperation(onCompletion: nil)
    }
    
    //MARK:- FTFinderViewControllerEditingDelegate
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectInsertAboveForPage page: FTPageProtocol?) {
        if let currentPage = page{
            self.insertEmptyPage(above: currentPage)
        }
    }

    func finderViewController(bookMark page: FTThumbnailable) {
        self.executer.execute(type: .bookmark(page: page))
        self.bookmarkInformer.updateBookmarkStatus(page.isBookmarked)
    }

    func finderViewController(didSelectDuplicate pages: [FTThumbnailable], onCompletion: (()->())?) {
        self.executer.execute(type: .duplicatePage(pages: pages), onCompletion: {
            if let pageIndex = self.currentlyVisiblePage()?.pageIndex() {
                self.showPage(at: Int(pageIndex),forceReLayout: true)
            }
            onCompletion?()
        })
    }

    func finderViewController(_ finderVc: FTFinderViewController, didSelectTag pages: NSSet, from source: UIView) {
        self.executer.execute(type: .tag(source: source, controller: finderVc, pages: pages))
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectInsertBelowForPage page: FTPageProtocol?) {
        if let currentPage = page{
            self.insertEmptyPage(below: currentPage)
        }
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectRemovePagesWithIndices indices: IndexSet) {
        finderViewController.reloadData();
    }
    
    func shouldShowMoveOperation(in finderViewController: FTFinderViewController) -> Bool {
        return true;
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectPages pages: NSSet, toMoveTo shelfItem: FTShelfItemProtocol) {
        finderViewController.reloadData();
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectShareWithPages pages: NSSet, exportTarget: FTExportTarget?) {
        finderViewController.dismiss(animated: true) { [weak self] in
            let pages = pages.allObjects as! [FTPageProtocol]
            exportTarget?.pages = pages.sorted(by: { (p1, p2) -> Bool in
                return (p1.pageIndex() < p2.pageIndex())
            });
            if let target = exportTarget {
            }
        }
    }
    
    
    func finderViewController(_ finderViewController: FTFinderViewController, pastePagesAtIndex index: Int?) {
        
        var insertedIndex: Int = 0
        if let idx = index {
            insertedIndex = abs(idx)
        } else {
            insertedIndex = (self.currentlyVisiblePage()?.pageIndex() ?? 0) + 1;
        }
        self.insertPagesFromClipBoard(atIndex: insertedIndex, showLoaderOnViewController: finderViewController) { (_, error) in
            if error == nil {
                finderViewController.reloadData()
            }
        }
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didMovePageAtIndex fromIndex: Int, toIndex: Int) {
        finderViewController.reloadData();
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectRotatePages  pages: NSSet) {
        var rotatedPageIndices = Set<Int>()
        for page in pages {
            if let thumnailable = page as? FTThumbnailable {
                thumnailable.rotate()
                rotatedPageIndices.insert(thumnailable.pageIndex())
            }
            NotificationCenter.default.post(name: NSNotification.Name.FTPageDidChangePageTemplate,
                                            object: page);
        }
        NotificationCenter.default.post(name: NSNotification.Name("FTDocumentGetReloaded"), object: nil)
    }
    
    //MARK:- Helper
    func updatePages(forFinderViewController finderViewController: FTFinderViewController) {
        finderViewController.reloadData();
    }
    
    func finderViewController(_ contorller: FTFinderViewController,
                              searchForKeyword searchKey: String,
                              onFinding: (() -> ())?,
                              onCompletion: (() -> ())?)
    {
        let newKeyword = (searchKey.count == 0) ? nil : searchKey;
        //Commented due to no realtime refresh
        
        /*if(newKeyword == self.finderSearchOptions.searchedKeyword) {
         if(nil != onCompletion) {
         onCompletion!();
         }
         return;
         }*/
        if (self.finderSearchOptions == nil){//Workaround to fix a crash (EXC_BREAKPOINT)
            onCompletion?()
            FTCLSLog("⚠️ finderSearchOptions null")
            return
        }
        self.finderSearchOptions.searchedKeyword = newKeyword;
        self.finderSearchOptions.searchPages = [FTThumbnailable]();
        if(nil == self.finderSearchOptions.searchedKeyword) {
          //  self.finderSearchOptions.searchPages = nil;
        }
        
        if let document = self.pdfDocument as? FTDocumentSearchProtocol {
            self.cancelSearchOperation(onCompletion: { [weak self] in
//                if(searchKey.isEmpty) {
//                    self?.finderSearchOptions.searchPages = nil;
//                    if(nil != onCompletion) {
//                        onCompletion!();
//                    }
//                }
//                else {
                    FTNotebookRecognitionHelper.activateMyScript("Finder_Search");
                    var tags:[String] = []
                    if let weakSelf = self{
//                        if(weakSelf.finderSearchOptions.filterOption == FTFilterOptionMenuItem.tagged){
                            let arTags = weakSelf.finderSearchOptions.selectedTags.map({ $0.text })
                            if !arTags.isEmpty {
                                tags.append(contentsOf: arTags as! [String]);
                            }
//                            else {
//                                tags.append(contentsOf: weakSelf.pdfDocument.allTags())
//                            }
                        //}
                    }
                    _ = document.searchDocumentsForKey(searchKey,
                                                       tags: tags,
                                                       isGlobalSearch: false,
                                                       onFinding: {(page, cancelled) in
                                                        if(!cancelled) {
                                                            DispatchQueue.main.async {
                                                                if let thumbPage = page as? FTThumbnailable {
                                                                    self?.finderSearchOptions.searchPages?.append(thumbPage);
                                                                }
                                                                onFinding?();
                                                            }
                                                        }
                    }, onCompletion: {(isCancelled) in
                        if(!isCancelled) {
                            if(nil != onCompletion) {
                                onCompletion!();
                            }
                        }
                    });
                //}
            });
        }
    }
    
    //MARK:- Start Searching :-
    private func cancelSearchOperation(onCompletion : (()->())?) {
        if let document = self.pdfDocument as? FTDocumentSearchProtocol {
            document.cancelSearchOperation(onCompletion: onCompletion);
        }
    }
    
    @objc func clearSearchOptionsInfo()
    {
        self.cancelSearchOperation(onCompletion: nil);
        if let finderOptions = self.finderSearchOptions {
            finderOptions.searchedKeyword = nil;
            finderOptions.searchPages = nil;
        }
    }
    
    func insertPagesFromClipBoard(atIndex index: Int, showLoaderOnViewController viewController: UIViewController, completionHandler : @escaping ((Bool,NSError?) -> Void)) {
        let loadingIndicator = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: viewController, withText: "")
        
        if let url = FTPasteBoardManager.shared.getBookUrl(),
            let document = self.pdfDocument as? FTNoteshelfDocument {
            let oldpageCount = self.numberOfPages();

            _ = document.insertDocumentAtURL(url,
                                             atIndex: index)
            { [weak self] (success, error) in
                guard let strongSelf = self else {
                    return;
                }
                loadingIndicator.hide()
                if let _error = error {
                    _error.showAlert(from: strongSelf)
                }
                else {
                    let newPageCount = strongSelf.pdfDocument.pages().count;
                    let pagesAdded = newPageCount - oldpageCount;
                    let currentPage = self?.currentlyVisiblePage()?.pageIndex() ?? 0;
                    if(pagesAdded > 0) {
                        strongSelf.refreshUIforInsertedPages(at: UInt(currentPage+1),
                                                             count: UInt(pagesAdded),
                                                             forceReLayout: true);
                    }
                }
                completionHandler(success, error)
            }
        } else {
            completionHandler(true, nil)
        }
    }
}
