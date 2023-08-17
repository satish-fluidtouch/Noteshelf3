//
//  DeskViewController+Finder.swift
//  Noteshelf
//
//  Created by Siva on 05/01/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension DeskViewController: FTThumbnailPickerViewControllerDelegate, FTThumbnailShareViewControllerDelegate, FTThumbnailsViewControllerEditingDelegate {
    //MARK:- Share
    func choosePagesToShare() {
        self.saveNotebookAndPerform(theSelector: #selector(self.presentShare));
    }
    
    @objc private func presentShare() {
        self.showThumbnails(forMode: .Share);
    }
    
    //Picker
    func showPicker() {
        self.saveNotebookAndPerform(theSelector: #selector(self.presentPicker));
    }
    
    @objc private func presentPicker() {
        self.showThumbnails(forMode: .Picker);
    }
    
    //Finder
    private func showThumbnails(forMode mode: FTThumbnailsMode) {
        //Wait until data services is done
        objc_sync_enter(DataServices.sharedDataServices())
        defer { objc_sync_exit(DataServices.sharedDataServices()) }
        
        self.view.userInteractionEnabled = true;
        
        let smartMessageView = self.view.viewWithTag(125453);
        smartMessageView?.removeFromSuperview();
        
        self.saveNotebookState(true, onCompletion: nil);
        
        if (0 == notebook.pages.count) {
            let smartMessageView = SmartMessageView(frame: self.view.bounds, message: NSLocalizedString("NoPagesToShowInFinder", comment: "No pages to show in finder"), style: kSmartMessageJustText);
            self.view.userInteractionEnabled = false;
            self.view.addSubview(smartMessageView);
            smartMessageView.dismissAfterInterval(1, delegate: self);
            return;
        }
        
        FTThumbnailsViewController.showThumbnailsPage(withPageCollectionDocument: self.notebook, onMode: mode, fromViewController: self, withDelegates: [self]);
    }
    
    //MARK:- FTThumbnailableCollectionDelegate
    var pageTransform: CGAffineTransform {
        if (self.writingView.isLandscape) {
            if (self.writingView.isInverted) {
                return CGAffineTransformMakeRotation(CGFloat(M_PI) * -0.5);
            }
            else {
                return CGAffineTransformMakeRotation(CGFloat(M_PI) * 0.5);
            }
        }
        return CGAffineTransformIdentity;
    };
    
    func currentPageIndex(in thumbnailsViewController: FTThumbnailsViewController) -> Int? {
        return Int(self.pageCurlView.currentPageIndex);
    }
    
    //MARK:- FTThumbnailPickerViewControllerDelegate
    func thumbnailsViewController(thumbnailsViewController: FTThumbnailsViewController, didSelectPageAtIndex index: Int) {
        thumbnailsViewController.dismissViewControllerAnimated(true, completion: {
            self.pageSelectedFromPageList(UInt(index));
        });
    }
    
    //MARK:- FTThumbnailsViewControllerEditingDelegate
    func thumbnailsViewController(thumbnailsViewController: FTThumbnailsViewController, didSelectDuplicateWithPages pages: NSSet) {
        FTCloudBackUpManager.sharedCloudBackUpManager().shelfItemDidGetUpdated(self.notebookShelfItem);
        
        self.refresh();
        
        thumbnailsViewController.reloadData();
    }
    
    func thumbnailsViewController(thumbnailsViewController: FTThumbnailsViewController, didSelectRemovePagesWithIndices indices: NSIndexSet) {
        self.refresh();
        
        thumbnailsViewController.reloadData();
    }
    
    func shouldShowMoveOperation(in thumbnailsViewController: FTThumbnailsViewController) -> Bool {
        return true;
    }
    
    func thumbnailsViewController(thumbnailsViewController: FTThumbnailsViewController, didSelectPages pages: NSSet, toMoveTo shelfItem: FTShelfItemModel) {
        self.refresh();
        
        thumbnailsViewController.reloadData();
    }
    
    func thumbnailsViewController(thumbnailsViewController: FTThumbnailsViewController, didSelectTagsWithPages pages: NSSet) {
//        print("didSelectTagsWithSelectedIndexes - \(selectedIndexes)");
    }
    
    func thumbnailsViewController(thumbnailsViewController: FTThumbnailsViewController, searchKeywordDidChange keyword: String, withCompletionHandler completionHandler: ((pages: [FTThumbnailable]) -> Void)) {
    }
    
    func thumbnailsViewController(thumbnailsViewController: FTThumbnailsViewController, didMovePageAtIndex fromIndex: Int, toIndex: Int) {
        if self.notebookShelfItem.enSyncEnabled
        {
            FTENPublishManager.recordSyncLog("User re-ordered pages of notebook: \(self.notebookShelfItem.title)");
//            FTENPublishManager.sharedPublishManager().udpateSyncRecordsOfShelfItemWithObjectID(self.notebookShelfItem, removeDeletedPageRecords: false, withAccount: EvernoteAccountUnknown);
        }
        FTCloudBackUpManager.sharedCloudBackUpManager().shelfItemDidGetUpdated(self.notebookShelfItem);
        
        self.refresh();
        
        thumbnailsViewController.reloadData();

    }
    
    //MARK:- FTThumbnailShareViewControllerDelegate
    func thumbnailsViewController(thumbnailsViewController: FTThumbnailsViewController, didSelectPages pages: NSSet) {
        thumbnailsViewController.dismissViewControllerAnimated(true, completion: {
            self.arraySelectedPages.addObjectsFromArray(pages.allObjects as! [FTNPage]);
            runInMainThread {
                self.showTargets();
            };
        });
    }
    
    //Helper
    private func saveNotebookAndPerform(theSelector selector: Selector) {
        self.normalizeDeskMode();
        
        if (writingView.isDirty)
        {
            self.view.userInteractionEnabled = false;
            
            let smartMessageView = SmartMessageView(frame: self.view.bounds, message: NSLocalizedString("SavingNotebook", comment: "Saving Notebook"), style: kSmartMessageActivityIndicator);
            smartMessageView.tag = 125453;
            self.view.addSubview(smartMessageView);
            
            runInMainThread(0.001, closure: {
                self.performSelector(selector);
            });
        }
        else
        {
            runInMainThread {
                self.performSelector(selector);
            };
        }
    }
}
