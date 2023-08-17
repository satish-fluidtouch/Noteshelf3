//
//  FTCloudAccountInfo.swift
//  Noteshelf
//
//  Created by Siva on 24/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTCloudAccountInfo: NSObject {
    var userName: String?;
    var consumedBytes: Int64?
    var totalBytes: Int64?
    var serverAddress : String?

    var loadingText = NSLocalizedString("Loading", comment: "Loading...");
    var statusText: String?;

    var percentage: Float {
        get {
            if let consumed = consumedBytes, let total = totalBytes {
                return min((Float(consumed) / Float(total)) * 100, 100);
            }
            return 0;
        }
    }

    func usernameFormatString() -> String {
        var userName = self.userName;
        if(nil == userName) {
            userName = FTEmptyDisplayName;
        }
        return userName!;
    }

    func spaceUsedFormatString() -> String {
        var formtableStr = ""
        if let totalSizeInBytes = self.totalBytes, let consumedSizeInBytes = self.consumedBytes {
            let totalSize = fileSize(Int64(totalSizeInBytes))
            let consumedSize = fileSize(Int64(consumedSizeInBytes))
            formtableStr = String(format: NSLocalizedString("AccountInfoFormat", comment: "%@ of %@ used on your"), consumedSize, totalSize)
        }
        return formtableStr
    }
}
