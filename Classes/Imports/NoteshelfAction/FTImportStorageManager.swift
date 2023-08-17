//
//  FTImportActionManager.swift
//  Noteshelf
//
//  Created by Matra on 10/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

enum FTImportStatus: Int {
    case notStarted
    case downloading
    case downloadFailed
    case readyToImport
    case importSuccess
    case importFailed
    case importRetrying
    
    func statusImage() -> String {
        var img : String;
        switch self {
        case .downloadFailed,.importFailed:
            img = "iconFailed";
        case .importSuccess:
            img = "iconImported";
        default:
            img = "iconSpin";
        }
        return img;
    }
}

private let SHARED_FOLDER_NAME = "SharedURLs"
private let PLIST_NAME = "SharedLinks.plist"

class FTImportStorageManager: NSObject {

    static func clearImportFilesIfNeeded(_ forcible: Bool = false) {
        if UserDefaults.standard.bool(forKey: "clear_import_files_Identifier") || forcible {
            UserDefaults.standard.removeObject(forKey: "clear_import_files_Identifier");
            self.store(shareLinks: [FTSharedAction]());
            try? FileManager().removeItem(at: self.storageDirectoryURL());
        }
    }
    
    static func addNewImportAction(_ importedURL:URL, group: String?, collection: String?) {
        let newAction:FTSharedAction = FTSharedAction()
        newAction.collectionName = collection
        newAction.groupName = group
        newAction.sourceURL = importedURL.absoluteString;

        let sharedDirectory = FTImportStorageManager.storageDirectoryURL()
        let uniqueFileName = FileManager.uniqueFileName(importedURL.lastPathComponent,
                                                        inFolder: sharedDirectory,
                                                        pathExt: importedURL.pathExtension);
        newAction.fileName = uniqueFileName
        if importedURL.isFileURL {
            let fileManager = FileManager()
            let destinationPath = sharedDirectory.appendingPathComponent(uniqueFileName)
            do {
                try fileManager.copyItem(at: importedURL, to: destinationPath)
                newAction.fileURL = destinationPath.path
                newAction.importStatus = .readyToImport
            }
            catch let error as NSError {
                fatalError("Error creating directory: \(error.localizedDescription)")
            }
        }
        var importActions = self.sharedLinks();
        importActions.insert(newAction, at: 0);
        let isWritten = self.store(shareLinks: importActions);
        #if DEBUG
        debugPrint("Is written :",isWritten,newAction.debugDescription)
        #endif
    }
        
    static func updateImportAction(_ editableAction:FTSharedAction)
    {
        var importActions = self.sharedLinks();
        let index = importActions.firstIndex(where: { (item) -> Bool in
            if(item.importGUID == editableAction.importGUID) {
                return true;
            }
            return false;
        });

        if let _index = index {
            importActions.remove(at: _index);
            importActions.insert(editableAction, at: _index);
            self.store(shareLinks: importActions);
        }
    }
        
    static func removeImportAction(_ removableAction:FTSharedAction){
        
        var importActions = self.sharedLinks();
        let index = importActions.firstIndex(where: { (item) -> Bool in
            if(item.importGUID == removableAction.importGUID) {
                return true;
            }
            return false;
        });
        if let _index = index {
            importActions.remove(at: _index);
            self.store(shareLinks: importActions);
        }
    }

    static func clearStorageAndGetUserActiveActions() -> [FTSharedAction]
    {
        let sharedLinks = self.sharedLinks();
        let resultArray = sharedLinks.filter { (eachItem) -> Bool in
            return (eachItem.importStatus != .downloadFailed
                && eachItem.importStatus != .importSuccess
                && eachItem.importStatus != .importFailed)
        }
        self.store(shareLinks: resultArray);
        return resultArray
    }
    
    static func resetCorruptedStatusWhenTerminated()
    {
        let sharedLinks = self.sharedLinks();
        sharedLinks.forEach { (eachItem) in
            if(eachItem.importStatus == .downloading) {
                eachItem.importStatus = .notStarted;
            }
        }
        self.store(shareLinks: sharedLinks);
    }

    static func getAllPendingActions() -> [FTSharedAction] {
        return FTImportStorageManager.sharedActionLinks(of: [.notStarted,.importRetrying]);
    }
    
    static func getReadyToImportActions() -> [FTSharedAction] {
        return FTImportStorageManager.sharedActionLinks(of: [.readyToImport]);
    }
        
    static func getInProgressDownloads() -> [FTSharedAction] {
        let status : [FTImportStatus] = [.downloading
            ,.downloadFailed
            ,.readyToImport
            ,.importSuccess
            ,.importFailed
            ,.importRetrying
        ]
        return FTImportStorageManager.sharedActionLinks(of: status);
    }
    
    static func storageDirectoryURL() -> URL
    {
        let fileManager = FileManager.default;
        let fileURL =  fileManager.containerURL(forSecurityApplicationGroupIdentifier:FTSharedGroupID.getAppGroupID())
        let directoryURL = fileURL!.appendingPathComponent(SHARED_FOLDER_NAME)
        if(!(FileManager().fileExists(atPath: directoryURL.path))) {
            self.createDirectoryAt(directoryURL)
        }
        return directoryURL
    }
}

//MARK:- Save/Load -
private extension FTImportStorageManager
{
    static func sharedLinks() -> [FTSharedAction]
    {
        var sharedActions = [FTSharedAction]();
        let plistPath = FTImportStorageManager.shareActionPlistURL()
        do {
            let data = try Data(contentsOf:plistPath)
            if let dictRoot = try PropertyListSerialization.propertyList(from: data,
                                                                         options: [],
                                                                         format: nil) as? [String: [[String:String]]] {
                let sharedLinks = dictRoot["sharedLinks"];
                sharedLinks?.forEach({ (dict) in
                    let action = FTSharedAction.init(dictionary: dict);
                    sharedActions.append(action);
                });
            }
        }
        catch {
            
        }
        return sharedActions;
    }

    @discardableResult static func store(shareLinks: [FTSharedAction]) -> Bool
    {
        var success = false;
        var linksInfo = [[String : Any]]();
        shareLinks.forEach { (eachAction) in
            linksInfo.append(eachAction.dictionaryRepresentation());
        }
        
        let dictRoot = ["sharedLinks": linksInfo];
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: dictRoot,
                                                          format: .xml,
                                                          options: 0);
            try data.write(to: FTImportStorageManager.shareActionPlistURL(), options: .atomicWrite)
            success = true
        }  catch {
            #if DEBUG
            debugPrint(error)
            #endif
        }
        return success;
    }
}

private extension FTImportStorageManager
{
    static func sharedActionLinks(of status : [FTImportStatus]) -> [FTSharedAction]
    {
        let sharedLinks = FTImportStorageManager.sharedLinks()
        let resultArray = sharedLinks.filter { (eachitem) -> Bool in
            return status.contains(eachitem.importStatus);
        };
        return resultArray
    }
}

//MARK:- Location -
private extension FTImportStorageManager
{
    static func createDirectoryAt(_ directoryURL:URL) {
        let fileManager = FileManager.default;
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            fatalError("Error creating directory: \(error.localizedDescription)")
        }
    }

    static func shareActionPlistURL() -> URL
    {
        let plistPath = FTImportStorageManager.storageDirectoryURL().appendingPathComponent(PLIST_NAME);
        return plistPath;
    }
}
