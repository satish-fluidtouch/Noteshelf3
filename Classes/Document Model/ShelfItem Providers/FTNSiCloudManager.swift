//
//  FTNSiCloudManager.swift
//  Noteshelf
//
//  Created by Akshay on 23/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

class FTNSiCloudManager: FTiCloudManager {
    private(set) var nsProductionURL: URL?
    private override init() {}

    override func updateiCloudStatus(_ containerID: String!, withCompletionHandler completionBlock: ((Bool) -> Void)!) {
        super.updateiCloudStatus(containerID, withCompletionHandler: { available in
#if !NOTESHELF_ACTION
            completionBlock(available && self.iCloudOn());
#else
            completionBlock(available);
#endif
        })
    }

    var cloudURLSToListen: [URL] {
        var urlsToListen = [URL]()
        if self.iCloudOn(), let cloudURL = self.iCloudRootURL() {
            urlsToListen.append(cloudURL);
        }
        return urlsToListen;
    }
}

extension FTNSiCloudManager {
#if ENTERPRISE_EDITION
    struct iCloudContainerID {
#if DEBUG
        static let ns3: String = "iCloud.com.fluidtouch.noteshelf3..enterprise-dev"
#else
        static let ns3: String = "iCloud.com.fluidtouch.noteshelf3.enterprise"
#endif
    }
#else
    struct iCloudContainerID {
#if DEBUG
        static let ns3: String = "iCloud.com.fluidtouch.noteshelf3-dev"
#elseif BETA
        static let ns3: String = "iCloud.com.fluidtouch.noteshelf3-beta"
#else
        static let ns3: String = "iCloud.com.fluidtouch.noteshelf3"
#endif
    }
#endif
}
