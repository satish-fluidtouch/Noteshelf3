//
//  FTDiagnosisCounter.swift
//  Noteshelf
//
//  Created by Amar on 13/03/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTRenderKit
#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
import FirebaseCrashlytics
#endif

class FTDiagnosticInstanceCounter: NSObject , FTDiagnosticCounter {
    @objc static let sharedInstance = FTDiagnosticInstanceCounter();
    
    fileprivate var crashInfo = [String : Any]();
    
    func incrementCounter(key : String) {
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        objc_sync_enter(self);
        var value = self.crashInfo[key] as? Int ?? 0;
        value += 1;
        self.crashInfo[key] = value;
        Crashlytics.crashlytics().setCustomValue(self.crashInfo, forKey: "Counters");
        objc_sync_exit(self);
        #endif
    }

    @objc
    func decrementCounter(key : String) {
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        objc_sync_enter(self);
        var value = self.crashInfo[key] as? Int ?? 0;
        value -= 1;
        self.crashInfo[key] = value;
        Crashlytics.crashlytics().setCustomValue(self.crashInfo, forKey: "Counters");
        objc_sync_exit(self);
        #endif
    }

    func logEvent(event : String)
    {
        objc_sync_enter(self);
        FTCLSLog("Diagnostics:"+event);
        objc_sync_exit(self);        
    }
}
