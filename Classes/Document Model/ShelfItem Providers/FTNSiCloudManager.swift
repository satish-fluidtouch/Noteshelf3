//
//  FTNSiCloudManager.swift
//  Noteshelf
//
//  Created by Akshay on 23/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

class FTNSiCloudManager {
    static let shared = FTNSiCloudManager()
    private(set) var nsProductionURL: URL?
    private init() {}

    //Objective-C automatically sgeesting the async version of override like below, we may need to change build settings to avoid this.
    // for now, I'm avaoiding override and created a similar method like below
    /*
    override func updateiCloudStatus(with containerID: String?) async -> Bool {
        let available = await super.updateiCloudStatus(with: containerID)
        return available
    }
     */
    func configureiCloudStatus(completionBlock: @escaping ((Bool) -> Void)) {
        FTiCloudManager.shared().updateiCloudStatus(iCloudContainerID.ns3) { available in
#if !NOTESHELF_ACTION
            if FTDocumentMigration.supportsMigration() {
                DispatchQueue.global().async {
                    self.nsProductionURL = try? FileManager().url(forUbiquityContainerIdentifier: iCloudContainerID.ns2);
                    DispatchQueue.main.async {
                        completionBlock(available || (nil != self.nsProductionURL));
                    }
                }
            }
            else {
                completionBlock(available && FTiCloudManager.shared().iCloudOn());
            }
#else
            completionBlock(available);
#endif
        }
    }

    var cloudURLSToListen: [URL] {
        var urlsToListen = [URL]()
        if FTiCloudManager.shared().iCloudOn(), let cloudURL = FTiCloudManager.shared().iCloudRootURL() {
            urlsToListen.append(cloudURL);
        }
        if let nsProductionURL {
            urlsToListen.append(nsProductionURL)
        }
        return urlsToListen;
    }
}

private extension FTNSiCloudManager {
    struct iCloudContainerID {
        static let ns2: String = "iCloud.com.fluidtouch.noteshelf"

#if DEBUG
        static let ns3: String = "iCloud.com.fluidtouch.noteshelf-dev"
#elseif BETA
        static let ns3: String = "iCloud.com.fluidtouch.noteshelf3-beta"
#else
        static let ns3: String = "iCloud.com.fluidtouch.noteshelf3"
#endif
    }
}
