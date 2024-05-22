//
//  FTRootViewCOntroller_ImportAction.swift
//  Noteshelf
//
//  Created by Amar on 30/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

private var shouldDisplayImportScreen = false;
private weak var importScreenViewController : FTImportedDocViewController?;

extension FTRootViewController {
    func configureForImportAction()
    {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleImportedDocumentsIfExist(_:)),
                                               name: NSNotification.Name.actionImportStatusDidUpdate,
                                               object: nil)
        FTImportActionManager.sharedInstance.startProcessingAllActions()
    }
    
    func showCompleteImportProgressIfNeeded() {
        if importSmartProgressView == nil {
            let count = FTImportStorageManager.getReadyToImportActions().count
            importProgress = Progress();
            importProgress?.totalUnitCount = Int64(count);
            importProgress?.localizedDescription = NSLocalizedString("Importing", comment: "Importing...");

            importSmartProgressView = FTSmartProgressView.init(progress: importProgress!);
            importSmartProgressView?.showProgressIndicator(NSLocalizedString("Importing", comment: "Importing..."),
                                                 onViewController: self);
        }
    }
    
    fileprivate func updateProgressCount()
    {
        if let importProgress {
            let totalCount = importProgress.totalUnitCount;
            let completedCount = importProgress.completedUnitCount + 1;

            var progressInfo = NSLocalizedString("Importing", comment: "Importing...");
            if(totalCount > 1) {
                let str = String.init(format: NSLocalizedString("NofNAlt", comment: "%d of %d"), completedCount,totalCount);

                progressInfo = progressInfo.appending("\n").appending(str);
            }
            importProgress.localizedDescription = progressInfo;
        }
      
    }
    
    func presentImportsControllerifNeeded()
    {
        FTImportActionManager.sharedInstance.startProcessingAllActions()
    }
    @objc
    private func handleImportedDocumentsIfExist(_ notification : Notification) {
        guard let importAction = notification.object as? FTSharedAction, importScreenViewController == nil else {
            return
        }
        if (importAction.importStatus == .downloadFailed)
            || (importAction.importStatus == .importSuccess)
            || (importAction.importStatus == .importFailed) {
            // 2- ImportStatus.DownloadFailed
            // 4- ImportStatus.ImportSuccess
            // 5- ImportStatus.ImportFailed
            FTImportActionManager.sharedInstance.startProcessingAllActions()
        }
    }
    
    func updateSmartProgressStatus(openDoc: Bool) {
        if openDoc {
            dismissProgressView()
        } else {
            updateProgressCount()
            importProgress?.completedUnitCount += 1
            if let importProgress {
                if importProgress.completedUnitCount == importProgress.totalUnitCount {
                    dismissProgressView()
                    shouldDisplayImportScreen = true;
                    _presentImportsControllerifNeeded()
                }
            } else {
                dismissProgressView()
            }
        }
    }
    
    internal func dismissProgressView() {
        importSmartProgressView?.hideProgressIndicator()
        importSmartProgressView = nil
        importProgress = nil
    }
    
    @objc private func _presentImportsControllerifNeeded() {
        if (nil != self.docuemntViewController)
            || !shouldDisplayImportScreen
            || self.applicationState() == .background {
            return
        }
        DispatchQueue.main.async {
            self.showImportedList()
        }
    }
    
    // MARK:- Show Import List View
    private func showImportedList() {
        shouldDisplayImportScreen = false;
        if(nil == importScreenViewController) {
            let importControllerList = FTImportedDocViewController.init(nibName: FTImportedDocViewController.className, bundle: nil)
            importControllerList.delegate = self;
            self.ftPresentModally(importControllerList, animated: true, completion: nil)
        }
    }
}

extension FTRootViewController : FTImportedDocViewControllerDelegate
{
    func importedDocumentController(_ controller: FTImportedDocViewController,
                                    didSelectShareAction action: FTSharedAction)
    {
        self.openDocumentForSelectedNotebook(URL(fileURLWithPath: action.documentUrlHash),
                                             isSiriCreateIntent: false);
    }
}
