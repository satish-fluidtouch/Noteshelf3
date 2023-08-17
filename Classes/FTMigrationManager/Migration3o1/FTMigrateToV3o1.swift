//
//  FTMigrateToV3o1.swift
//  Noteshelf
//
//  Created by Amar on 05/09/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FirebaseCrashlytics

protocol FTMigrateTo3o1 {
    func performMigrationTo3o1() -> Bool;
}

//for migration to 3.1
class FTMigrateToV3o1 : NSObject {
    func performMigration()
    {
        let sharedDefaults = FTUserDefaults.defaults();
        let value = sharedDefaults.float(forKey: "migrationVersion");
        if(value < 3.1) {
            //for ns documents
            let moveDocToShare = FTMigrateNSDocumentsToShared();
            if(!moveDocToShare.performMigration()) {
                Crashlytics.crashlytics().crash();
            }
            
            //for library covers
            let coverTheme =  FTThemesStorage(themeLibraryType: FTNThemeLibraryType.covers)
            if(!coverTheme.performMigrationTo3o1()) {
                Crashlytics.crashlytics().crash();
            }
            
            //for library papers
            let paperTheme = FTThemesStorage(themeLibraryType: FTNThemeLibraryType.papers);
            if(!paperTheme.performMigrationTo3o1()) {
                Crashlytics.crashlytics().crash();
            }
            
            //for userdefaults documents
            _ = FTUserDefaults().performMigrationTo3o1();
        }
    }
}

fileprivate class FTMigrateNSDocumentsToShared : NSObject {
    func performMigration() -> Bool
    {
        var success = true;
        
        var isDir = ObjCBool.init(false);
        let localNSURL = FTUtils.noteshelfDocumentsDirectoryBefore3o1();
        let defaultManager = FileManager();
        if(defaultManager.fileExists(atPath: localNSURL.path, isDirectory: &isDir) && isDir.boolValue) {
            let newURL = FTUtils.noteshelfDocumentsDirectoryInSharedLoc();
            isDir = ObjCBool.init(false);
            if(!defaultManager.fileExists(atPath: newURL.path, isDirectory: &isDir) || !isDir.boolValue) {
                do {
                    try defaultManager.moveItem(at: localNSURL, to: newURL);
                }
                catch {
                    success = false;
                    FTLogError("Migration Failed", attributes: ["Description":error.localizedDescription]);
                }
            }
        }

        return success;
    }
}
