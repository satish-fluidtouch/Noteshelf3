//
//  FTThemeStorage_Migrate3o1.swift
//  Noteshelf
//
//  Created by Ramakrishna on 26/08/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTThemesStorage : FTMigrateTo3o1
{
    private var pathToLocalThemesFolderBefore3o1: URL {
        get {
            let libraryDirectoryURL = self.libraryURLBefore3o1;
            let localThemesFolderName = self.themeLibraryType.themeCacheFolderName();
            return libraryDirectoryURL.appendingPathComponent(localThemesFolderName);
        }
    }
    
    private var libraryURLBefore3o1 : URL {
        get {
            let libraryDirectory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory,
                                                                       FileManager.SearchPathDomainMask.userDomainMask,
                                                                       true).first;
            let libraryDirectoryURL = URL.init(fileURLWithPath: libraryDirectory!);
            return libraryDirectoryURL;
        }
    }
    
    private var downloadedThemesFolderURLBefore3o1 : URL {
        get {
            return self.pathToLocalThemesFolderBefore3o1.appendingPathComponent("downloaded");
        }
    };
    
    private var customThemesFolderURLBefore3o1 : URL {
        get {
            return self.pathToLocalThemesFolderBefore3o1.appendingPathComponent("custom");
        }
    };
    
    private var recentsPlistURLBefore3o1 : URL {
        get {
            return self.pathToLocalThemesFolderBefore3o1.appendingPathComponent("recents.plist");
        }
    };
    
    func performMigrationTo3o1() -> Bool {
        var success = true;
        success = FileManager.migrateItem(atPath: self.downloadedThemesFolderURLBefore3o1,
                                          toPath: self.downloadedThemesFolderURL);
        if(success) {
            success = FileManager.migrateItem(atPath: self.customThemesFolderURLBefore3o1,
                                              toPath: self.customThemesFolderURL);
        }
        
        if(success) {
            success = FileManager.migrateItem(atPath: self.recentsPlistURLBefore3o1,
                                              toPath: self.recentsPlistURL);
        }
        
        if(success) {
            let themesFilesName = ["themes_v8_de.plist",
                                   "themes_v8_en.plist",
                                   "themes_v8_es.plist",
                                   "themes_v8_fr.plist",
                                   "themes_v8_it.plist",
                                   "themes_v8_ja.plist",
                                   "themes_v8_zh-Hans.plist",
                                   "themes_v8_zh-Hant.plist"];
            for eachFileName in themesFilesName {
                let sourceURL = self.libraryURLBefore3o1.appendingPathComponent(eachFileName);
                let destination = self.themesMetadataFolderURL.appendingPathComponent(eachFileName);
                success = FileManager.migrateItem(atPath: sourceURL, toPath: destination);
                if(!success) {
                    break;
                }
            }
        }
        return success
    }
}

fileprivate extension FileManager
{
    static func migrateItem(atPath source : URL,toPath destination : URL) -> Bool
    {
        var success = true;
        let defaultManager = FileManager();
        if(defaultManager.fileExists(atPath: source.path)) {
            do {
                try? defaultManager.removeItem(at: destination);
                try defaultManager.moveItem(at: source, to: destination);
            }
            catch {
                success = false;
                FTLogError("Migration Failed", attributes: ["Description":error.localizedDescription]);
            }
        }
        return success;
    }
}

