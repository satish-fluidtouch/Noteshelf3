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
            let error = NSError(domain: "EDAMErrorDomain", code: Int(EDAMErrorCode_AUTH_EXPIRED.rawValue), userInfo: nil)
            self.delegate?.didCompletePublishRequestWithError?(request: self,error:error)
            return
        }
        EvernoteNoteStore(session: evernoteSession).listNotebooks { [self] notebooks in
            self.executeBlock(onPublishQueue: { [self] in
                if let noteBooks = notebooks as? [EDAMNotebook] {
                    for notebook in noteBooks {
                        if notebook.name.lowercased() == "noteshelf" {
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
                            self.delegate?.didCompletePublishRequestWithError?(request: self,error:nil)
                        })
                    } failure: { error in
                        self.executeBlock(onPublishQueue: { [self] in
                            FTENSyncUtilities.recordSyncLog("Failed to create Noteshelf notebook:\(String(describing: error))")
                            self.delegate?.didCompletePublishRequestWithError?(request: self,error:error)
                        })
                    }
                } else {
                    self.delegate?.didCompletePublishRequestWithError?(request: self,error:nil)
                }
            })

        } failure: { error in
            self.executeBlock(onPublishQueue: { [self] in
                if let error = error {
                    FTENSyncUtilities.recordSyncLog("Failed to fetch notebooks from Evernote: \(error)")
                }
                self.delegate?.didCompletePublishRequestWithError?(request: self,error:error)
            })
        }
#endif
    }
}
