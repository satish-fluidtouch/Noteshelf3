//
//  FTShelfItemPublishRequest_Extension.swift
//  Noteshelf
//
//  Created by Siva on 15/05/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
#if !targetEnvironment(macCatalyst)
import Evernote_SDK_iOS
#endif

#if !targetEnvironment(macCatalyst)
extension FTShelfItemPublishRequest {
    @objc func createNote(forShelfItemRecord shelfItemRecord: ENSyncRecord) {
        #if !targetEnvironment(macCatalyst)
        let filePath = shelfItemRecord.fullURLPath;
        if ((nil != filePath) && FileManager.default.fileExists(atPath: filePath!)) {
            let url = URL(fileURLWithPath: filePath!);
            let newNote = EDAMNote();
            var noteName  = url.title;
            //Todo: Check for nil shelf item title
            noteName = noteName.validatingForEvernoteNoteName();
            newNote.title = noteName as String;
            
            let evernotePublishManager = FTENPublishManager.shared;
            if (shelfItemRecord.isBusinessNote) {
                newNote.notebookGuid = evernotePublishManager.noteshelfBusinessNotebookGuid;
            }
            else {
                newNote.notebookGuid = evernotePublishManager.noteshelfNotebookGuid;
            }
            
            let attributes = EDAMNoteAttributes();
            
            let map = EDAMLazyMap();
            let keys: Set<String> = [EVERNOTE_CONSUMER_KEY];
            map.keysOnly = keys;
            
            attributes.contentClass = EVERNOTE_NOTESHELF_CONTENT_CLASS;
            attributes.applicationData = map;
            
            newNote.attributes = attributes;
            newNote.created = NSNumber(value: (url.fileModificationDate as NSDate).edamTimestamp as Int64);
            
            FTENSyncUtilities.recordSyncLog(String.init(format: "Creating note for shelf item with name: %@", noteName));
            
            newNote.content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\"><en-note></en-note>";
            
            guard EvernoteSession.shared().isAuthenticated else {
                let error = NSError(domain: "ENPagePublish", code: 401, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("EvernoteAuthenticationFailed",comment: "Unable to authenticate with Evernote")]);
                FTENSyncUtilities.recordSyncLog(String(format: "Failed with Error:%@",error as CVarArg));
                self.delegate?.didCompletePublishRequestWithError!(error);
                return;
            }
            
            shelfItemRecord.noteStoreClient().create(newNote, completion: { (note, error) in
                if let error = error {
                    self.executeBlock(onPublishQueue: {
                        FTENSyncUtilities.recordSyncLog(String(format: "Failed to create a note with error %@",error as CVarArg));
                        self.delegate?.didCompletePublishRequestWithError!(error);
                    });
                }
                else {
                    self.executeBlock(onPublishQueue: {
                        do {
                            let shelfItemRecord = try self.managedObjectContext()?.existingObject(with: self.objectID!) as! ENSyncRecord;
                            
                            shelfItemRecord.isDirty = false;
                            shelfItemRecord.enGUID = note?.guid;
                            self.commitDataChanges();
                            FTENSyncUtilities.recordSyncLog("Note created successfully");
                            
                            self.delegate?.didCompletePublishRequestWithError!(nil);
                        }
                        catch let error as NSError {
                            self.delegate?.didCompletePublishRequestWithError!(error);
                            return;
                        }
                    });
                }
            })
        }
        else
        {
            //If we dont find the shelfItem corresponding to ENSyncRecord, we can skip it for now. User may save it next time in correct path.
            FTENSyncUtilities.recordSyncLog("Did not find the ShelfItem corresponding to ENSyncRecord");
            self.ignore(syncRecrod: shelfItemRecord);
        }
        #endif
    }
    
    
    @objc func updateNote(forShelfItemRecord shelfItemRecord: ENSyncRecord) {
        #if !targetEnvironment(macCatalyst)
        let filePath = shelfItemRecord.fullURLPath;
        if ((nil != filePath) && (FileManager.default.fileExists(atPath: filePath!))) {
            let url = URL(fileURLWithPath: filePath!);
            
            guard EvernoteSession.shared().isAuthenticated else {
                let error = NSError(domain: "ENPagePublish", code: 401, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("EvernoteAuthenticationFailed",comment: "Unable to authenticate with Evernote")]);
                FTENSyncUtilities.recordSyncLog(String(format: "Failed with Error:%@",error as CVarArg));
                self.delegate?.didCompletePublishRequestWithError!(error);
                return;
            }
            
            shelfItemRecord.noteStoreClient().fetchNote(withGuid: shelfItemRecord.enGUID, includingContent: false, resourceOptions: ENResourceFetchOption.includeAttributes) { (note, error) in
                if let error = error {
                    self.executeBlock(onPublishQueue: {
                        if (error as NSError).code == ENErrorCode.notFound.rawValue {
                            self.noteDidGetDeletedFromEvernote();
                        }
                        else {
                            FTENSyncUtilities.recordSyncLog(String(format: "Failed to update note with error %@",error as CVarArg));
                            self.delegate?.didCompletePublishRequestWithError!(error);
                        }
                    });
                }
                else {
                    self.executeBlock(onPublishQueue: {
                        do {
                            let shelfItemRecord = try self.managedObjectContext()?.existingObject(with: self.objectID!) as! ENSyncRecord;
                            
                            FTENSyncUtilities.recordSyncLog(String.init(format: "Updating notebook with name: %@", url.title));
                            
                            //Update any changes done to title.
                            var noteName = url.title;
                            //Todo: Check for nil shelf item title
                            noteName = noteName.validatingForEvernoteNoteName();
                            note?.title = noteName;
                            
                            note?.updated = NSNumber(value: (url.fileModificationDate as NSDate).edamTimestamp as Int64);
                            
                            guard EvernoteSession.shared().isAuthenticated else {
                                let error = NSError(domain: "ENPagePublish", code: 401, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("EvernoteAuthenticationFailed",comment: "Unable to authenticate with Evernote")]);
                                FTENSyncUtilities.recordSyncLog(String(format: "Failed with Error:%@",error as CVarArg));
                                self.delegate?.didCompletePublishRequestWithError!(error);
                                return;
                            }
                            
                            shelfItemRecord.noteStoreClient().update(note!, completion: { (updatedNote, error) in
                                if let error = error {
                                    self.executeBlock(onPublishQueue: {
                                        FTENSyncUtilities.recordSyncLog(String(format: "Failed with error %@",error as CVarArg));
                                        self.delegate?.didCompletePublishRequestWithError!(error);
                                    });
                                }
                                else {
                                    self.executeBlock(onPublishQueue: {
                                        
                                        shelfItemRecord.isDirty = false;
                                        self.commitDataChanges();
                                        FTENSyncUtilities.recordSyncLog("Note updated successfully");
                                        
                                        self.delegate?.didCompletePublishRequestWithError!(nil);
                                    });
                                }
                            });
                        }
                        catch let error as NSError {
                            self.executeBlock(onPublishQueue: {
                                FTENSyncUtilities.recordSyncLog(String(format: "Failed with error %@",error as CVarArg));
                                self.delegate?.didCompletePublishRequestWithError!(error);
                            });
                            return;
                        }
                    });
                }
            };
        }
        else
        {
            //If we dont find the shelfItem corresponding to ENSyncRecord, we can skip it for now. User may save it next time in correct path.
            FTENSyncUtilities.recordSyncLog("Did not find the ShelfItem corresponding to ENSyncRecord");
            self.ignore(syncRecrod: shelfItemRecord);
        }
        #endif
    }
    
    private func ignore(syncRecrod: ENSyncRecord) {
        let entry = FTENIgnoreEntry();
        if nil == syncRecrod.url {
            FTLogError("EN-ShelfItem: URL nil");
        }
        entry.title = syncRecrod.url;
        if nil == syncRecrod.nsGUID {
            FTLogError("EN-ShelfItem: nsGUID nil");
        }
        entry.notebookID = syncRecrod.nsGUID;
        entry.ignoreType = .fileNotFound;
        entry.shouldDisplay = false;
        self.delegate?.didCompletePublishRequest?(withIgnore: entry)
    }
    
}
#endif
