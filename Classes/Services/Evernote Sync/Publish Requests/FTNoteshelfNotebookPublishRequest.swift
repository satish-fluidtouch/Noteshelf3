//
//  FTNoteshelfNotebookPublishRequest.swift
//  Noteshelf
//
//  Created by Ramakrishna on 14/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTNoteshelfNotebookPublishRequest : FTBasePublishRequest {
    
    override init(object refObject: NSManagedObjectID?, delegate: FTBasePublishRequestDelegate?) {
        super.init(object: refObject, delegate: delegate)
        self.delegate = delegate
    }
    override func startRequest(){
        super.startRequest()
        FTENPublishManager.recordSyncLog("Listing personal notebooks")
        #if !targetEnvironment(macCatalyst)
        guard let evernoteSession = EvernoteSession.shared() else {
            self.delegate?.didCompletePublishRequestWithError?(nil)
            return
        }
        if let authToken = evernoteSession.authenticationToken as? String {
            EvernoteNoteStore(session: evernoteSession).listLinkedNotebooks { [self] notebooks in
                self.executeBlock(onPublishQueue: { [self] in
                    if let noteBooks = notebooks as? [EDAMLinkedNotebook] {
                        for notebook in noteBooks {
                            if notebook.shareName.lowercased() == "noteshelf" {
                                FTENPublishManager.shared.noteshelfNotebookGuid = notebook.guid
                                break
                            }
                        }
                    }
                    if FTENPublishManager.shared.noteshelfNotebookGuid == nil{
                        FTENPublishManager.recordSyncLog("Creating Noteshelf notebook")
                        let newNoteBook = EDAMNotebook()
                        newNoteBook?.name = "Noteshelf"
                        EvernoteNoteStore(session: evernoteSession).createNotebook(newNoteBook) { notebook in
                            self.executeBlock(onPublishQueue: { [self] in
                                FTENSyncUtilities.recordSyncLog("Successfully created notebook")
                                if let notebook = notebook{
                                    FTENPublishManager.shared.noteshelfNotebookGuid = notebook.guid
                                }
                                self.delegate?.didCompletePublishRequestWithError?(nil)
                            })
                        } failure: { error in
                            self.executeBlock(onPublishQueue: { [self] in
                                if let error = error {
                                    FTENSyncUtilities.recordSyncLog("Failed to create Noteshelf notebook:\(error)")
                                    self.delegate?.didCompletePublishRequestWithError?(error)
                                }
                            })
                        }
                    } else {
                        self.delegate?.didCompletePublishRequestWithError?(nil)
                    }
                })

            } failure: { error in
                self.executeBlock(onPublishQueue: { [self] in
                    if let error = error {
                        FTENSyncUtilities.recordSyncLog("Failed to fetch notebooks from Evernote: \(error)")
                    }
                    self.delegate?.didCompletePublishRequestWithError?(error)
                })
            }
        }
        #endif
    }
}
