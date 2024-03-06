//
//  FTFileItemPlist_FTCacheableFileItem.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 28/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTFileItemPlist {
    override func saveItemToCache(_ destination: URL) -> Bool {
        var success = false;
        if fileName == PROPERTIES_PLIST, var contents = self.contentDictionary {
            contents["relativePath"] = rootFileItem.fileItemURL.relativePathWRTCollection();
            do {
                let data = try PropertyListSerialization.data(fromPropertyList: contents, format: .xml, options: 0)
                try data.write(to: destination, options: .atomic);
                
                let sourceDate = self.fileItemURL.fileModificationDate;
                try FileManager().setAttributes([.modificationDate:sourceDate], ofItemAtPath: destination.path(percentEncoded: false));
                
                success = true;
            }
            catch {
                debugLog("error: \(error)")
            }
        }
        else {
            success = super.saveItemToCache(destination);
        }
        return success;
    }
    
    private  var rootFileItem: FTFileItem {
        var item: FTFileItem = self;
        while let parent = item.parent {
            item = parent;
        }
        return item;
    }
    
    override func shouldCache(_ cachedFileURL: URL) -> Bool {
        if fileName == PROPERTIES_PLIST {
            return true;
        }
        return super.shouldCache(cachedFileURL);
    }
}
