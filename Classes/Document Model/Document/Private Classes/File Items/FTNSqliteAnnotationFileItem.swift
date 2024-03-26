//
//  FTNSqliteAnnotationFileItem.swift
//  Noteshelf
//
//  Created by Amar on 14/10/16.
//
//

import Foundation
import FTRenderKit
import FTDocumentFramework

class FTNSqliteAnnotationFileItem : FTFileItemSqlite
{
    fileprivate var annotationsArray : [FTAnnotation]?;
    fileprivate var _annotationGroups : FTAnnotationGroups<String, NSMutableOrderedSet>?;
    weak var associatedPage : FTPageProtocol?;
    
    var annotations : [FTAnnotation] {
        get{
            objc_sync_enter(self);
            if nil == self.annotationsArray {
                self.loadAnnotations();
            }
            objc_sync_exit(self);
            return self.annotationsArray ?? [FTAnnotation]();
        }
        set{
            objc_sync_enter(self);
            self.annotationsArray = newValue;
            self.updateContent(newValue as NSObjectProtocol);
            objc_sync_exit(self);
        }
    }

    private var annotationGroups : FTAnnotationGroups<String, NSMutableOrderedSet> {
        get{
            objc_sync_enter(self);
            if nil == self._annotationGroups {
                self.loadAnnotations();
            }
            objc_sync_exit(self);
            return self._annotationGroups ?? FTAnnotationGroups();
        }
        set{
            objc_sync_enter(self);
            self._annotationGroups = newValue;
            objc_sync_exit(self);
        }
    }

    func addAnnotation(_ annotation :FTAnnotation,atIndex : Int = -1)
    {
        if(atIndex == -1) || (atIndex > self.annotations.count) {
            self.annotations.append(annotation);
        }
        else {
            self.annotations.insert(annotation, at: atIndex);
        }
        self.updateContent(self.annotations as NSObjectProtocol);

        // If the annotation contains a groupID, add it to a group
        if let groupId = annotation.groupId {
            if var groupAnnotations = annotationGroups.value(forKey: groupId) {
                groupAnnotations.add(annotation)
                annotationGroups.setValue(groupAnnotations, forKey: groupId)
            } else {
                annotationGroups.setValue([annotation], forKey: groupId)
            }
        }

        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        if(annotation.shouldAddToPageTile) {
            (self.associatedPage as? FTPageTileAnnotationMap)?.tileMapAddAnnotation(annotation);
        }
        #endif
    }
    
    func removeAnnotation(_ annotation : FTAnnotation)
    {
        let index = annotationsArray?.firstIndex(of: annotation);
        if (index != nil && index != NSNotFound)
        {
            self.annotations.remove(at: index!);
            if let groupId = annotation.groupId {
                if var groupAnnotations = annotationGroups.value(forKey: groupId) {
                    groupAnnotations.remove(annotation)
                    annotationGroups.setValue(groupAnnotations, forKey: groupId)
                }
            }
            self.updateContent(self.annotations as NSObjectProtocol);
            #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
            if(annotation.shouldAddToPageTile) {
                (self.associatedPage as? FTPageTileAnnotationMap)?.tileMapRemoveAnnotation(annotation);
            }
            #endif
        }
    }

    func move(annotation: FTAnnotation, to index: Int) {
        if let indexToRemove = annotationsArray?.firstIndex(of: annotation) {
            self.annotations.remove(at: indexToRemove)
            if(index == -1) || (index > self.annotations.count) {
                self.annotations.append(annotation);
            } else {
                self.annotations.insert(annotation, at: index);
            }

            self.updateContent(self.annotations as NSObjectProtocol);

            #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
            if(annotation.shouldAddToPageTile) {
                (self.associatedPage as? FTPageTileAnnotationMap)?.tileMapAddAnnotation(annotation);
            }
            #endif
        }
    }

    override func saveDatabaseChanges() -> Bool {
        FTCLSLog("annotation save pageIndex:\(self.associatedPage?.pageIndex() ?? 0)");
        var success = false;
        let strokeAnnotationsByRemovingErasedSegments = self.finalizedAnnotationsToSaveFromAnnotations(self.annotations);
        
        if strokeAnnotationsByRemovingErasedSegments.isEmpty {
            //Nothing to save
            self.resetDatabase();
            return true;
        }
        
        let localTempPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString);
        try? FileManager().removeItem(at: localTempPath);
        guard let dbqueue = FMDatabaseQueue.init(path: localTempPath.path) else {
            return false;
        }
        _ = self.createSchema(dbqueue);
        dbqueue.inDatabase { (dbToSave) in
                dbToSave.open();
                dbToSave.beginTransaction();
                dbToSave.executeStatements("PRAGMA auto_vacuum = 1; PRAGMA journal_mode = OFF");

                for eachAnnotation in strokeAnnotationsByRemovingErasedSegments {
                    _ = eachAnnotation.saveContents();
                    success = eachAnnotation.saveToDatabase(dbToSave);
                    if(!success) {
                        FTCLSLog("FAILED TO SAVE");
                    }
                }
                FTCLSLog("PDF Page Saved");
                dbToSave.commit();
                dbToSave.close();
        };
        do {
            _ = try FileManager().replaceItemAt(self.fileItemURL, withItemAt: localTempPath);
        }
        catch {
            success = false;
        }
        return success;
    }
    
    fileprivate func loadAnnotations()
    {
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        (self.associatedPage as? FTPageTileAnnotationMap)?.clearMapCache();
        #endif
        var annotations = [FTAnnotation]();
        var annotationGroups: FTAnnotationGroups<String, NSMutableOrderedSet> = FTAnnotationGroups();
        if (false == self.schemaExists()) {
            self.annotationsArray = annotations;
            self._annotationGroups = annotationGroups;
            return;
        }
        var shouldSaveOnRepair = false
        self.databaseQueue.inDatabase { (db) in
            db.open();
           
            let annotationQuery = "SELECT * from annotation";
            let set = db.executeQuery(annotationQuery, withParameterDictionary: nil);
            if let _set = set, _set.columnCount > 0 {
                while(_set.next()) {
                        if let annotation = FTAnnotation.annotation(forSet: _set) {
                            annotation.associatedPage = self.associatedPage;
                            annotation.loadContents();
                            annotations.append(annotation);
                            #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
                            if(annotation.shouldAddToPageTile) {
                                (self.associatedPage as? FTPageTileAnnotationMap)?.tileMapAddAnnotation(annotation);
                            }
                            #endif

                            // If the annotation contains a groupID, add it to a group
                            if let groupId = annotation.groupId {
                                if var groupAnnotations = annotationGroups.value(forKey: groupId) {
                                    groupAnnotations.add(annotation)
                                    annotationGroups.setValue(groupAnnotations, forKey: groupId)
                                } else {
                                    annotationGroups.setValue([annotation], forKey: groupId)
                                }
                            }
                            shouldSaveOnRepair = annotation.repairIfRequired() || shouldSaveOnRepair
                        }
                }
            }
            set?.close();
            db.close();
            self.annotationsArray = annotations;
            self._annotationGroups = annotationGroups
            if shouldSaveOnRepair {
                self.associatedPage?.isDirty = true
                track("corrupted_annotation_repaired", params: nil, screenName: "Backend", shouldLog: true)
            }
        }
    }
    
    fileprivate func schemaExists() -> Bool
    {
        guard let fileURL = self.fileItemURL else {
            return false;
        }

        if (!FileManager.default.fileExists(atPath: fileURL.path)) {
            return false;
        }
        var success : Bool = false;
        
        self.databaseQueue.inDatabase { (db) in
            db.open();
            let checkForTavleQuery = "SELECT name FROM sqlite_master WHERE type='table' AND name='annotation'";
            let set = db.executeQuery(checkForTavleQuery, withParameterDictionary: nil);
            if(nil != set) {
                success = set!.next();
                set!.close();
            }
            db.close();
        }
        return success;
    }
    
    private func createSchema(_ dbQueue : FMDatabaseQueue) -> Bool
    {
        var success = false;
        dbQueue.inDatabase { (db) in
            db.open();
            db.beginTransaction()
            success = db.executeUpdate(FTAnnotation.annotationQuery, withParameterDictionary: [:]);
            if(!success) {
                NSLog("failed To create Table");
            }
            db.commit();
            db.close();
        }
        return success;
    }
    
    //MARK:Splitting erased segments
    fileprivate func finalizedAnnotationsToSaveFromAnnotations(_ inAnnotations : [FTAnnotation]) -> [FTAnnotation]
    {
        var localAnnotations = [FTAnnotation]();
        localAnnotations.append(contentsOf: inAnnotations);
        var finalSetOfAnnotations = [FTAnnotation]();
        
        //Go through each annotation and split any stroke that has erased segments in it
        for eachAnnotation in localAnnotations {
            let resultantAnnotations = eachAnnotation.finalizeToSaveToDB();
            if(!resultantAnnotations.isEmpty) {
                finalSetOfAnnotations.append(contentsOf: resultantAnnotations);
            }
        }
        return finalSetOfAnnotations;
    }

    
    func textAnnotationsContainingKeyword(_ keyWord : String) -> [FTAnnotation]
    {
        var textAnnotations = [FTAnnotation]();
        if (false == self.schemaExists()) {
            return textAnnotations;
        }
        self.databaseQueue.inDatabase({ (db) in
            db.open();
            var keywordSelQuery = "SELECT * from annotation WHERE nonAttrText like ('%%%@%%')";
            keywordSelQuery = String.init(format: keywordSelQuery, keyWord);
            let set = db.executeQuery(keywordSelQuery, withParameterDictionary: nil);
            
            if let _set = set , _set.columnCount > 0 {
                while(_set.next()) {
                    let annotationType = _set.annotationType();
                    if(annotationType == .text) {
                        if let annotation = FTAnnotation.annotation(forSet: _set) {
                            annotation.associatedPage = self.associatedPage;
                            annotation.loadContents();
                            textAnnotations.append(annotation);
                        }
                    }
                }
            }
            set?.close();
            db.close();
        });
        return textAnnotations;
    }
    
    func annotataionsWithResources() -> [FTAnnotation]
    {
        var annotationsToReturn = [FTAnnotation]();
        let typesOfAnnotation: [Int] = [FTAnnotationType.image.rawValue,
                                        FTAnnotationType.sticky.rawValue,
                                        FTAnnotationType.audio.rawValue,
                                        FTAnnotationType.sticker.rawValue,
                                        FTAnnotationType.webclip.rawValue];
        if let _anotations = self.annotationsArray {
            annotationsToReturn = _anotations.filter({typesOfAnnotation.contains($0.annotationType.rawValue)})
            return annotationsToReturn;
        }
        
        if (false == self.schemaExists()) {
            return annotationsToReturn;
        }
        
        self.databaseQueue.inDatabase({ (db) in
            db.open();
            let keywordSelQuery = "SELECT * from annotation WHERE annotationType IN (?,?,?)";
            let set = db.executeQuery(keywordSelQuery, withArgumentsIn: typesOfAnnotation);
            if let _set = set , _set.columnCount > 0 {
                while(_set.next()) {
                    if let annotation = FTAnnotation.annotation(forSet: _set) {
                        annotation.associatedPage = self.associatedPage;
                        annotation.loadContents();
                        annotationsToReturn.append(annotation);
                    }
                }
            }
            set?.close();
            db.close();
        });
        return annotationsToReturn;
    }

    override func unloadContentsOfFileItem() {
        objc_sync_enter(self);
        if(!self.isModified) {
            super.unloadContentsOfFileItem();
            self.annotationsArray = nil;
            self._annotationGroups = nil
        }
        objc_sync_exit(self);
    }

    // MARK: Groups
    func group(annotations: [FTAnnotation]) {
        let groupId = UUID().uuidString
        annotations.forEach{ $0.groupId = groupId }
        self.annotationGroups.setValue(NSMutableOrderedSet(array: annotations), forKey: groupId)
    }

    func ungroup(annotations: [FTAnnotation]) {
        // If multiple groups got selected, accumulate all the group ids and remove them
        var groupIds = Set<String>()
        annotations.forEach{ annotation in
            if let groupId = annotation.groupId {
                groupIds.insert(groupId)
                annotation.groupId = nil
            }
        }
        groupIds.forEach { groupID in
            self.annotationGroups.removeValue(forKey: groupID)
        }
    }

    func annotations(groupId: String) -> [FTAnnotation]? {
        if let annotations = annotationGroups.value(forKey: groupId) {
            return annotations.array as? [FTAnnotation]
        }
        return nil
    }
}
