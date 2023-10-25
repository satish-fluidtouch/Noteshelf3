//
//  FTNoteshelfBusinessNotebookPublishRequest.swift
//  Noteshelf
//
//  Created by Ramakrishna on 13/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import Evernote_SDK_iOS

class FTNoteshelfBusinessNotebookPublishRequest : FTNoteshelfNotebookPublishRequest {
    
    override func startRequest(){
        super.startRequest()
        FTENPublishManager.recordSyncLog("Listing business notebooks")
        #if !targetEnvironment(macCatalyst)
        guard let evernoteSession = EvernoteSession.shared() else {
            self.delegate?.didCompletePublishRequestWithError?(nil)
            return
        }
        if let authToken = evernoteSession.authenticationToken as? String {
            EvernoteNoteStore(session: evernoteSession).listLinkedNotebooks { [weak self] notebooks in
                self?.executeBlock(onPublishQueue: { [weak self] in
                    var linkedNotebook: EDAMLinkedNotebook?

                    if let linkedNoteBooks = notebooks as? [EDAMLinkedNotebook]{
                        for notebook in linkedNoteBooks {
                            if notebook.shareName.lowercased() == "noteshelf"{
                                linkedNotebook = notebook
                                break
                            }
                        }
                    }
                    if linkedNotebook == nil{
                        FTENPublishManager.recordSyncLog("Creating Noteshelf Business-Notebook")
                        let newNoteBook = EDAMNotebook()
                        newNoteBook?.name = "Noteshelf"
//                        EvernoteSession.shared().businessNoteStore()?.createBusinessNotebook(
//                        newNoteBook) { [weak self] notebook, error in
//
//                            if(nil != error) {
//                                self?.executeBlock(onPublishQueue: {
//                                    FTENPublishManager.recordSyncLog("Failed to create Business-Notebook:\(String(describing: error))")
//                                    self?.delegate?.didCompletePublishRequestWithError?(error)
//                                })
//                            }
//                            else {
//                                self?.executeBlock(onPublishQueue: {
//                                    FTENPublishManager.recordSyncLog("Successfully created Business-Notebook")
//                                    if let notebook = notebook{
//                                        self?.fetchSharedNotebook(notebookLinked: notebook)
//                                    }
//                                })
//                            }
//                        }
                    }
                    else {
                        if let notebook = linkedNotebook {
                            self?.fetchSharedNotebook(notebookLinked: notebook);
                        }
                    }
                })

            } failure: { error in
                FTENPublishManager.recordSyncLog("Failed to fetch notebooks from Evernote:\(String(describing: error))")

                self.delegate?.didCompletePublishRequestWithError?(error)
            }
        }
        #endif
    }
    #if !targetEnvironment(macCatalyst)
    func fetchSharedNotebook(notebookLinked : EDAMLinkedNotebook){
//        let noteStoreForLinkedNotebook = EvernoteSession.shared().noteStore(for: notebookLinked)
//
//        noteStoreForLinkedNotebook.fetchSharedNotebookByAuth(completion: { [weak self] sharedNotebook, error in
//            if nil != error {
//                self?.executeBlock(onPublishQueue: { [self] in
//                    if let error = error {
//                        FTENSyncUtilities.recordSyncLog("Failed to get shared notebook from evernote with error \(error)")
//                    }
//                    self?.delegate?.didCompletePublishRequestWithError?(error)
//                })
//            } else {
//                if let notebookGuid = sharedNotebook?.notebookGuid {
//                    FTENPublishManager.recordSyncLog("Fetched details of the  business notebook: \(notebookGuid)")
//                }
//                FTENPublishManager.shared.noteshelfBusinessNotebookGuid = sharedNotebook?.notebookGuid
//            }
//        })
    }
    #endif
}
