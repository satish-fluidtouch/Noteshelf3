//
//  FTEvernoteExporter+FolderSearch.swift
//  Noteshelf
//
//  Created by Siva on 25/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
#if !targetEnvironment(macCatalyst)
import EvernoteSDK
#endif

let EvernoteRootFolder = FTCloudRootFolder;

extension FTEvernoteExporter : FTExporterProtocol{
    //MARK:- FolderSearch
    @objc func fetchFolderObject(withCompletionHandler completionHandler: @escaping FolderSearchCompletionHandler)
    {
        self.folderSearchCompletionHandler = completionHandler;
        
        let folderInfo = UserDefaults.standard.value(forKey: PersistenceKey_ExportTarget_FolderID_Evernote) as? NSDictionary
        #if !targetEnvironment(macCatalyst)
        let session = ENSession.shared;
        let noteStore = session.primaryNoteStore();
        
        if nil == folderInfo {
            self.fetchDefaultNotebook();
        }
        else {
            let guid = folderInfo!["guid"] as! String;
            
            if nil != noteStore {
                noteStore?.fetchNotebook(withGuid: guid, completion: { (notebook, error) in
                    if(nil != error) {
                        self.fetchDefaultNotebook();
                    }
                    else {
                        self.setAsCurrentNotebook(notebook);
                    }
                })
            }
        }
        #endif
    }
    
    func fetchDefaultNotebook() {
        #if !targetEnvironment(macCatalyst)
        let session = ENSession.shared;
        let noteStore = session.primaryNoteStore();
        
        noteStore?.listNotebooks(completion: { (notebooks, error) in
            if let _ = error {
                self.folderSearchCompletionHandler(nil, false);
            }
            else {
                if let notebooks = notebooks  {
                    let noteshelfNotebooks = notebooks.filter {$0.name == EvernoteRootFolder};
                    if noteshelfNotebooks.count > 0 {
                        self.setAsCurrentNotebook(noteshelfNotebooks[0]);
                    }
                    else {
                        self.createDefaultNotebook();
                    }
                }
            }
        });
        #endif
    }
    
    fileprivate func createDefaultNotebook() {
        #if !targetEnvironment(macCatalyst)
        let session = ENSession.shared;
        let noteStore = session.primaryNoteStore();
        let newNotebook = EDAMNotebook();
        newNotebook.name = EvernoteRootFolder;
        
        noteStore?.create(newNotebook, completion: { (notebook, error) in
            if let _ = error {
                self.folderSearchCompletionHandler(nil, false);
            }
            else {
                self.setAsCurrentNotebook(notebook);
            }
        });
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

