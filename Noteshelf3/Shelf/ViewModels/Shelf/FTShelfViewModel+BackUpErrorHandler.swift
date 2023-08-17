//
//  FTShelfViewModel+BackUpErrorHandler.swift
//  Noteshelf3
//
//  Created by Narayana on 02/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension FTShelfViewModel {
    func hasEvernotePublishError() -> Bool {
        var hasError = false
        if((UserDefaults.standard.object(forKey: EVERNOTE_PUBLISH_ERROR) != nil)
           || !(FTENIgnoreListManager.shared.ignoredNotebooks().filter({$0.shouldDisplay}).isEmpty)) {
            hasError = true
        }
        return hasError
    }

    func hasDropboxPublishError() -> Bool {
        var hasError = false
        if((UserDefaults.standard.object(forKey: BACKUP_ERROR) != nil)
           || ((FTCloudBackUpManager.shared.activeCloudBackUpManager?.ignoreList.ignoredItemsForUIDisplay().count ?? 0) > 0)) {
            hasError = true
        }
        return hasError
    }
}
