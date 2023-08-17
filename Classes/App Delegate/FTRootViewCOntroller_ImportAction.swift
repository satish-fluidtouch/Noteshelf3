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
    
    func presentImportsControllerifNeeded()
    {
        FTImportActionManager.sharedInstance.startProcessingAllActions()
        self.perform(#selector(_presentImportsControllerifNeeded), with: nil, afterDelay: 0.5)
    }
    @objc
    private func handleImportedDocumentsIfExist(_ notification : Notification) {
        guard let importAction = notification.object as? FTSharedAction else {
            return
        }
        
        if(
            (nil != importScreenViewController)
            || (nil != self.docuemntViewController)
            ) {
            return;
        }

        if (importAction.importStatus == .downloadFailed)
            || (importAction.importStatus == .importSuccess)
            || (importAction.importStatus == .importFailed) {
            // 2- ImportStatus.DownloadFailed
            // 4- ImportStatus.ImportSuccess
            // 5- ImportStatus.ImportFailed
            shouldDisplayImportScreen = true;
            FTImportActionManager.sharedInstance.startProcessingAllActions()
            _presentImportsControllerifNeeded()
        }
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
