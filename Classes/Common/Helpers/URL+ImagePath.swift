//
//  URL+ImagePath.swift
//  Noteshelf
//
//  Created by Dev_Guest on 28/09/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import FTCommon
import UIKit

private extension UserDefaults {
    static func groupUserDefaults() -> UserDefaults {
        return UserDefaults(suiteName: FTSharedGroupID.getAppGroupID())!;
    }
}

extension URL {
    /*
    static func triggerICloud()
    {
        if UserDefaults.groupUserDefaults().bool(forKey: "iCloudOn"), (nil == icloudURL) {
            if(FileManager().ubiquityIdentityToken != nil) {
                let sema = DispatchSemaphore.init(value: 0);
                DispatchQueue.global().async {
                    icloudURL = FileManager().url(forUbiquityContainerIdentifier: nil);
                    sema.signal();
                }
                sema.wait();
            }
        }
    }
     */

    func localRelativePathWRTDocuments() -> String
    {
        if(self.isCloudItem()) {
            return self.path;
        }
        else {
            let noteshelfURL = NSURL.noteshelfDocumentsDirectory().urlByDeleteingPrivate();
            return self.urlByDeleteingPrivate().path.replacingOccurrences(of: noteshelfURL.path, with: "");
        }
    }
    
    func isUbiquitousFileExists() -> Bool
    {
        return FileManager().isUbiquitousItem(at: self)

        // Old approach of checking Ubiquitous status removing now, to solve the intra container iCloud Status
        /*
        if #available(iOS 14.0, *) {
            if(nil == icloudURL) {
                URL.triggerICloud();
            }

            if let ubiPath = icloudURL?.urlByDeleteingPrivate().path,
               self.urlByDeleteingPrivate().path.contains(ubiPath) {
                if(FileManager().fileExists(atPath: self.path)) {
                    return true;
                }
                let lastComp = self.lastPathComponent;
                let metaCloudURL = self.deletingLastPathComponent().appendingPathComponent(".\(lastComp).icloud");
                if(FileManager().fileExists(atPath: metaCloudURL.path)) {
                    return true;
                }
            }
            return false;
        }
        else {
            return FileManager().isUbiquitousItem(at: self)
        }
         */
    }
    
    func isCloudItem() -> Bool
    {
        if(self.isUbiquitousFileExists()) {
            return true;
        }
        /*
        if(nil == icloudURL) {
            URL.triggerICloud();
        }

        if let ubiPath = icloudURL {
            if(self.urlByDeleteingPrivate().path.contains(ubiPath.urlByDeleteingPrivate().path)) {
                return true;
            }
        }
         */
        return false;
    }
}

extension NSURL
{
    static func noteshelfDocumentsDirectory() -> URL
    {
        let docURL = FileManager().containerURL(forSecurityApplicationGroupIdentifier: FTSharedGroupID.getAppGroupID());
        let noteURL = docURL!.appendingPathComponent("Noteshelf.nsdata", isDirectory: true);
        return noteURL;
    }
}
