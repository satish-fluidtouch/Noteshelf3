//
//  FTEvernoteExporter+FolderSearch.swift
//  Noteshelf
//
//  Created by Siva on 25/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
#if !targetEnvironment(macCatalyst)
// import EvernoteSDK
#endif

let EvernoteRootFolder = FTCloudRootFolder;

extension FTEvernoteExporter : FTExporterProtocol{
    //MARK:- FolderSearch
    @objc func fetchFolderObject(withCompletionHandler completionHandler: @escaping FolderSearchCompletionHandler)
    {
        self.folderSearchCompletionHandler = completionHandler;

        let folderInfo = UserDefaults.standard.value(forKey: PersistenceKey_ExportTarget_FolderID_Evernote) as? NSDictionary
        #if !targetEnvironment(macCatalyst)
        guard let session = EvernoteSession.shared(), session.isAuthenticated else {
            let error = NSError(domain: "ENPagePublish", code: 401, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("EvernoteAuthenticationFailed",comment: "Unable to authenticate with Evernote")]);
            FTENSyncUtilities.recordSyncLog(String(format: "Failed with Error:%@",error as CVarArg));
            return;
        }

        if nil == folderInfo {
            self.fetchDefaultNotebook();
        }
        else {
            let guid = folderInfo!["guid"] as! String;
            EvernoteNoteStore(session: session).getNotebookWithGuid(guid) { notebook in
                self.setAsCurrentNotebook(notebook);
            } failure: { error in
                self.fetchDefaultNotebook();
            }
        }
        #endif
    }
    
    func fetchDefaultNotebook() {
        #if !targetEnvironment(macCatalyst)
        guard let session = EvernoteSession.shared(), session.isAuthenticated else {
            let error = NSError(domain: "ENPagePublish", code: 401, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("EvernoteAuthenticationFailed",comment: "Unable to authenticate with Evernote")]);
            FTENSyncUtilities.recordSyncLog(String(format: "Failed with Error:%@",error as CVarArg));
            return;
        }
        EvernoteNoteStore(session: session).listNotebooks { [self] notebooks in
            if let notebooks = notebooks as? [EDAMNotebook]  {
                let noteshelfNotebooks = notebooks.filter {$0.name == EvernoteRootFolder};
                if noteshelfNotebooks.count > 0 {
                    self.setAsCurrentNotebook(noteshelfNotebooks[0]);
                }
                else {
                    self.createDefaultNotebook();
                }
            }

        } failure: { error in
            self.folderSearchCompletionHandler(nil, false);
        }
        #endif
    }
    
    fileprivate func createDefaultNotebook() {
        #if !targetEnvironment(macCatalyst)
        guard let session = EvernoteSession.shared(), session.isAuthenticated else {
            let error = NSError(domain: "ENPagePublish", code: 401, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("EvernoteAuthenticationFailed",comment: "Unable to authenticate with Evernote")]);
            FTENSyncUtilities.recordSyncLog(String(format: "Failed with Error:%@",error as CVarArg));
            return;
        }
        let newNotebook = EDAMNotebook();
        newNotebook?.name = EvernoteRootFolder;
        EvernoteNoteStore(session: session).createNotebook(newNotebook) { notebook in
            self.setAsCurrentNotebook(notebook);
        } failure: { error in
            self.folderSearchCompletionHandler(nil, false);
        }
        #endif
    }
    #if !targetEnvironment(macCatalyst)
    func setAsCurrentNotebook(_ notebook: EDAMNotebook!) {
        let userDefaults = UserDefaults.standard;
        userDefaults.setValue([
            "name": notebook.name,
            "guid": notebook.guid,
        ], forKey: PersistenceKey_ExportTarget_FolderID_Evernote);
        userDefaults.setValue(notebook.name, forKey: "\(PersistenceKey_ExportTarget_Evernote)_FolderName");
        userDefaults.synchronize();
        self.folderSearchCompletionHandler(notebook, true);
    }
    #endif
}

