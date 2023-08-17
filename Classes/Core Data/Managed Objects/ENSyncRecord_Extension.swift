//
//  ENSyncRecord_Extension.swift
//  Noteshelf
//
//  Created by Siva on 23/06/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension ENSyncRecord {
    var fullURLPath: String? {
        let fileURL = self.url;
        if(nil == fileURL) {
            return nil;
        }
        if(nil == FTENPublishManager.shared.rootDocumentsURL) {
            return nil;
        }
        return FTENPublishManager.shared.rootDocumentsURL?.appendingPathComponent(fileURL!).path;
    }
}
