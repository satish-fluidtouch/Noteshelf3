//
//  FTAITokenInfo.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 09/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTAITokenInfo: NSObject {
    var consumedToken: Int = 0;
    var lastResetDate: Date = Date.utcDate.startDayOfMonth();
    
    convenience init(with info:[String:Any]) {
        self.init();
        self.consumedToken = (info["consumedToken"] as? NSNumber)?.intValue ?? 0;
        if let dateString = (info["resetDate"] as? String) {
            lastResetDate = Date.dateFromUTC(dateString);
        }
    }
    
    var dictInfo: [String:Any] {
        var info = [String:Any]();
        info["consumedToken"] = consumedToken;
        info["resetDate"] = lastResetDate.utcDateString;
        return info;
    }
    
    func reset() {
        consumedToken = 0;
        lastResetDate = Date.utcDate.startDayOfMonth();
    }
}
