//
//  FTShelfItemPublishRequest_Extension.swift
//  Noteshelf
//
//  Created by Siva on 15/05/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import CoreData
#if !targetEnvironment(macCatalyst)
// import EvernoteSDK
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
            newNote?.title = noteName as String;
            
            let evernotePublishManager = FTENPublishManager.shared;
            if (shelfItemRecord.isBusinessNote) {
                newNote?.notebookGuid = evernotePublishManager.noteshelfBusinessNotebookGuid;
            }
            else {
                newNote?.notebookGuid = evernotePublishManager.noteshelfNotebookGuid;
            }
            
            let attributes = EDAMNoteAttributes();
            
            let map = EDAMLazyMap();
            map?.keysOnly = NSMutableSet(array: Array([EVERNOTE_CONSUMER_KEY])) ;
            
            attributes?.contentClass = EVERNOTE_NOTESHELF_CONTENT_CLASS;
            attributes?.applicationData = map;
            
            newNote?.attributes = attributes;
            newNote?.created = (url.fileModificationDate as NSDate).enedamTimestamp();
            FTENSyncUtilities.recordSyncLog(String.init(format: "Creating note for shelf item with name: %@", noteName));
            
            newNote?.content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\"><en-note></en-note>";
            
            guard let session = EvernoteSession.shared() ,session.isAuthenticated else {
                let error = FTENPublishError.authError;
                FTENSyncUtilities.recordSyncLog(String(format: "Failed with Error:%@",error as CVarArg));
                self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
                return;
            }
            EvernoteNoteStore(session: session).createNote(newNote) { note in
                self.executeBlock(onPublishQueue: {
                    do {
                        let shelfItemRecord = try self.managedObjectContext()?.existingObject(with: self.objectID!) as! ENSyncRecord;
                        
                        shelfItemRecord.isDirty = false;
                        shelfItemRecord.enGUID = note?.guid;
                        self.commitDataChanges();
                        FTENPublishManager.shared.ftENNotebook?.edamNote = note
                        if let resources = note?.resources as? [EDAMResource]{
                            FTENPublishManager.shared.ftENNotebook?.edamResources = resources
                        }
                        FTENSyncUtilities.recordSyncLog("Note created successfully");
                        
                        self.delegate?.didCompletePublishRequestWithError?(request: self,error:nil);
                    }
                    catch let error as NSError {
                        self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
                        return;
                    }
                });
            } failure: { error in
                self.executeBlock(onPublishQueue: {
                    FTENSyncUtilities.recordSyncLog(String(format: "Failed to create a note with error %@",error?.localizedDescription ?? ""));
                    self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
                });
            }
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
            
            guard let session = EvernoteSession.shared(), session.isAuthenticated else {
                let error = FTENPublishError.authError;
                FTENSyncUtilities.recordSyncLog(String(format: "Failed with Error:%@",error as CVarArg));
                self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
                return;
            }
            
            EvernoteNoteStore(session: session).getNoteWithGuid(shelfItemRecord.enGUID, withContent: false, withResourcesData: true, withResourcesRecognition: true, withResourcesAlternateData: false) { note in
                self.executeBlock(onPublishQueue: {
                    do {
                        let shelfItemRecord = try self.managedObjectContext()?.existingObject(with: self.objectID!) as! ENSyncRecord;
                        
                        FTENSyncUtilities.recordSyncLog(String.init(format: "Updating notebook with name: %@", url.title));
                        
                        //Update any changes done to title.
                        var noteName = url.title;
                        //Todo: Check for nil shelf item title
                        noteName = noteName.validatingForEvernoteNoteName();
                        note?.title = noteName;
                        note?.updated =  (url.fileModificationDate as NSDate).enedamTimestamp();
                        
                        guard EvernoteSession.shared().isAuthenticated else {
                            let error = FTENPublishError.authError;
                            FTENSyncUtilities.recordSyncLog("Failed with error \(error)");
                            self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
                            return;
                        }
                        
                        EvernoteNoteStore(session: session).update(note) { updatedNote in
                            self.executeBlock(onPublishQueue: {
                                shelfItemRecord.isDirty = false;
                                self.commitDataChanges();
                                FTENSyncUtilities.recordSyncLog("Note updated successfully");
                                self.delegate?.didCompletePublishRequestWithError?(request: self,error:nil);
                            });
                        } failure: { error in
                            self.executeBlock(onPublishQueue: {
                                FTENSyncUtilities.recordSyncLog("Failed with error \(error)");
                                self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
                            });
                        };
                    }
                    catch let error as NSError {
                        self.executeBlock(onPublishQueue: {
                            FTENSyncUtilities.recordSyncLog("Failed with error \(error)");
                            self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
                        });
                        return;
                    }
                });
                
                
            } failure: { error in
                self.executeBlock(onPublishQueue: {
                    if let nsEror = error as? NSError, nsEror.code == Int(EDAMErrorCode_UNKNOWN.rawValue) {
                        self.noteDidGetDeletedFromEvernote();
                    }
                    else {
                        FTENSyncUtilities.recordSyncLog("Failed to update note with error \(error)");
                        self.delegate?.didCompletePublishRequestWithError?(request: self,error:error);
                    }
                });
            }
        }
        else {
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
        self.delegate?.didCompletePublishRequest?(request: self, withIgnore: entry)
    }
}
#endif
