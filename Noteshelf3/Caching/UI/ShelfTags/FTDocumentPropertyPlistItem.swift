//
//  File.swift
//  Noteshelf3
//
//  Created by Siva on 06/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
class FTDocumentPropertyPlistItem: FTFileItemPlist {
    fileprivate var _tags : [String] = [String]()
    
    override init(fileName: String!, isDirectory isDir: Bool) {
        super.init(fileName: fileName, isDirectory: isDir);
    }

    override init!(url: URL!, isDirectory isDir: Bool) {
        super.init(url: url, isDirectory: isDir);
    }

        var tags : [String] {
            get {
                objc_sync_enter(self)
                if(_tags.count == 0) {
                    let docTags = self.contentDictionary["tags"] as? [String]
                    self._tags = docTags ?? []
                }
                objc_sync_exit(self)
                return self._tags
            }
            set{
                objc_sync_enter(self)
                self._tags = newValue;
                self.setObject(self._tags, forKey: "tags");
                objc_sync_exit(self);
            }
        }

    override func saveContentsOfFileItem() -> Bool {
        objc_sync_enter(self)
        self.setObject(self._tags, forKey: "tags")
        objc_sync_exit(self);
        return super.saveContentsOfFileItem();
    }
}
