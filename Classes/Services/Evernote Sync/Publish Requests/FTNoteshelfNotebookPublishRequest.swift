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
        EvernoteSession.shared().primaryNoteStore()?.listNotebooks(completion: { [self] notebooks, error in
            if nil != error {
                self.executeBlock(onPublishQueue: { [self] in
                    if let error = error {
                        FTENSyncUtilities.recordSyncLog("Failed to fetch notebooks from Evernote: \(error)")
                    }
                    self.delegate?.didCompletePublishRequestWithError?(error)
                })
            } else {
                self.executeBlock(onPublishQueue: { [self] in
                    
                    if let noteBooks = notebooks {
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
                        newNoteBook.name = "Noteshelf"
                        EvernoteSession.shared().primaryNoteStore()?.create(newNoteBook){[self] (notebook : EDAMNotebook?, error:Error?) -> Void in
                            if (nil != error) {
                                self.executeBlock(onPublishQueue: { [self] in
                                    if let error = error {
                                        FTENSyncUtilities.recordSyncLog("Failed to create Noteshelf notebook:\(error)")
                                        self.delegate?.didCompletePublishRequestWithError?(error)
                                    }
                                })
                            }else{
                                self.executeBlock(onPublishQueue: { [self] in
                                    FTENSyncUtilities.recordSyncLog("Successfully created notebook")
                                    if let notebook = notebook{
                                        FTENPublishManager.shared.noteshelfNotebookGuid = notebook.guid
                                    }
                                    self.delegate?.didCompletePublishRequestWithError?(nil)
                                })
                            }
                        }
                    }
                    else{
                        self.delegate?.didCompletePublishRequestWithError?(nil)
                    }
                })
            }
        })
        #endif
    }
}
