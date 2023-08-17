//
//  NSUbiquitousKeyValueStore_Extension.swift
//  Noteshelf
//
//  Created by Amar on 19/03/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

let FTUbiquitousKeyValueStoreChangedLocally = "FTUbiquitousKeyValueStoreChangedLocally";

let FTUbiquityiWatchPairedKey = "FTUbiquityiWatchPairedKey";
let FTUbiquityiWatchAppInstalledKey = "FTUbiquityiWatchAppInstalledKey";
let FTUBiquityiWatchInfoKey = "FTUBiquityiWatchInfoKey";

extension NSUbiquitousKeyValueStore  {
    func updateStatus(watchPaired : Bool,watchAppInstalled : Bool) {
        DispatchQueue.main.async {
        if(watchPaired) {
            #if !targetEnvironment(macCatalyst)
            
            var ubiquityInfo = [String:Bool]();
            ubiquityInfo[FTUbiquityiWatchPairedKey] = true;
            if(watchAppInstalled) {
                ubiquityInfo[FTUbiquityiWatchAppInstalledKey] = true;
            }
            else {
                ubiquityInfo[FTUbiquityiWatchAppInstalledKey] = false;
            }
            self.set(ubiquityInfo, forKey: FTUBiquityiWatchInfoKey);
            self.synchronize();
            #endif
        }
        else {
            self.removeObject(forKey: FTUBiquityiWatchInfoKey);
            self.synchronize();
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: FTUbiquitousKeyValueStoreChangedLocally),
                                        object: nil);
        }
    }
    
    @objc func isWatchAppInstalled() -> Bool {
        var appInstalled = false;
        if(self.isWatchPaired()) {
            let info = self.dictionary(forKey: FTUBiquityiWatchInfoKey);
            if(nil != info) {
                appInstalled = info![FTUbiquityiWatchAppInstalledKey] as! Bool;
            }
        }
        return appInstalled
    }
    
    @objc func isWatchPaired() -> Bool {
        var watchPaired = false;
        let info = self.dictionary(forKey: FTUBiquityiWatchInfoKey);
        if(nil != info) {
            watchPaired = info![FTUbiquityiWatchPairedKey] as! Bool;
        }
        return watchPaired
    }
}
