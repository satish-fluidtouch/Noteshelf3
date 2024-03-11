//
//  FTNoteshelfBusinessNotebookPublishRequest.swift
//  Noteshelf
//
//  Created by Ramakrishna on 13/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
// import EvernoteSDK

class FTNoteshelfBusinessNotebookPublishRequest : FTNoteshelfNotebookPublishRequest {
    
    override func startRequest(){
        super.startRequest()
        FTENPublishManager.recordSyncLog("Listing business notebooks")
        #if !targetEnvironment(macCatalyst)
        guard let evernoteSession = EvernoteSession.shared() else {
            let error = NSError(domain: "EDAMErrorDomain", code: Int(EDAMErrorCode_AUTH_EXPIRED.rawValue), userInfo: nil)
            self.delegate?.didCompletePublishRequestWithError?(request: self, error: error)
            return
        }
        FTENSyncUtilities.recordSyncLog("BU-listLinkedNotebooks", prefix: "API-▶️")
        EvernoteNoteStore(session: evernoteSession).listLinkedNotebooks { [weak self] notebooks in
            self?.executeBlock(onPublishQueue: { [weak self] in
                FTENSyncUtilities.recordSyncLog("BU-listLinkedNotebooks", prefix: "API-✅")
                var linkedNotebook: EDAMLinkedNotebook?

                if let linkedNoteBooks = notebooks as? [EDAMLinkedNotebook]{
                    for notebook in linkedNoteBooks {
                        if notebook.shareName.lowercased() == "noteshelf"{
                            linkedNotebook = notebook
                            break
                        }
                    }
                }
                if linkedNotebook == nil {
                    FTENPublishManager.recordSyncLog("Creating Noteshelf Business-Notebook")
                    let newNoteBook = EDAMNotebook()
                    newNoteBook?.name = "Noteshelf"
                    FTENSyncUtilities.recordSyncLog("BU-createBusinessNotebook", prefix: "API-▶️")
                    EvernoteNoteStore(session: evernoteSession).createBusinessNotebook(newNoteBook) { notebook in
                        self?.executeBlock(onPublishQueue: {
                            FTENSyncUtilities.recordSyncLog("BU-createBusinessNotebook", prefix: "API-✅")
                            FTENPublishManager.recordSyncLog("Successfully created Business-Notebook")
                            if let notebook = notebook{
                                self?.fetchSharedNotebook(notebookLinked: notebook)
                            }
                        })
                    } failure: { error in
                        self?.executeBlock(onPublishQueue: {
                            FTENSyncUtilities.recordSyncLog("BU-createBusinessNotebook", prefix: "API-🔴")
                            FTENPublishManager.recordSyncLog("Failed to create Business-Notebook:\(String(describing: error))")
                            self?.delegate?.didCompletePublishRequestWithError?(request: self,error:error)
                        })
                    }
                }
                else {
                    if let notebook = linkedNotebook {
                        self?.fetchSharedNotebook(notebookLinked: notebook);
                    }
                }
            })

        } failure: { error in
            self.executeBlock(onPublishQueue: {
                FTENSyncUtilities.recordSyncLog("BU-listLinkedNotebooks", prefix: "API-🔴")
                FTENPublishManager.recordSyncLog("Failed to fetch notebooks from Evernote:\(String(describing: error))")
                
                self.delegate?.didCompletePublishRequestWithError?(request: self,error:error)
            })
        }
        #endif
    }
    #if !targetEnvironment(macCatalyst)
    func fetchSharedNotebook(notebookLinked : EDAMLinkedNotebook){
        guard let evernoteSession = EvernoteSession.shared() else {
            let error = NSError(domain: "EDAMErrorDomain", code: Int(EDAMErrorCode_AUTH_EXPIRED.rawValue), userInfo: nil)
            self.delegate?.didCompletePublishRequestWithError?(request: self,error:error)
            return
        }
        FTENSyncUtilities.recordSyncLog("BU-getSharedNotebookByAuth", prefix: "API-▶️")
        EvernoteNoteStore(session: evernoteSession).getSharedNotebookByAuth { sharedNotebook in
            self.executeBlock(onPublishQueue: {
                FTENSyncUtilities.recordSyncLog("BU-getSharedNotebookByAuth", prefix: "API-✅")
                if let notebookGuid = sharedNotebook?.notebookGuid {
                    FTENPublishManager.recordSyncLog("Fetched details of the  business notebook: \(notebookGuid)")
                }
                FTENPublishManager.shared.noteshelfBusinessNotebookGuid = sharedNotebook?.notebookGuid
                self.delegate?.didCompletePublishRequestWithError?(request: self, error: nil);
            })
        } failure: { error in
            self.executeBlock(onPublishQueue: { [self] in
                FTENSyncUtilities.recordSyncLog("BU-getSharedNotebookByAuth", prefix: "API-🔴")
                if let error = error {
                    FTENSyncUtilities.recordSyncLog("Failed to get shared notebook from evernote with error \(error)")
                }
                self.delegate?.didCompletePublishRequestWithError?(request: self,error:error)
            })
        }
    }
    #endif
}
