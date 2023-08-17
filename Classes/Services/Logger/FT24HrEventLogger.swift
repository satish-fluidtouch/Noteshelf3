//
//  FT24HrEventLogger.swift
//  Noteshelf
//
//  Created by Amar on 29/07/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

private struct FT24HrEventKey {
    static let eventsInfoKey = "24HrEvents"
    static let dateKey = "dateKey"
    static let counterKey = "counterKey"
}

class FT24HrEventLogger: NSObject {

    private var maxCounter: Int = 0;
    private var eventName: String;
    private var screenName: String?;
    
    private var eventCounter: Int = 0;
    private var eventLastDate: Date?;
    
    static func trackEvent(_ event: String,
                           screen: String?,
                           maxCounter: Int,
                           param: [String:Any]?) {
        DispatchQueue.global(qos: .background).async {
            objc_sync_enter(UserDefaults.standard);
            let obj = FT24HrEventLogger(event: event,
                                        screen: screen,
                                        maxCounter: maxCounter);
            obj.trackEvent(param);
            objc_sync_exit(UserDefaults.standard);
        }
    }
    
    required init(event: String, screen: String?,maxCounter counter: Int) {
        maxCounter = counter;
        eventName = event;
        screenName = screen;
        
        super.init();
        let info = self.eventInfo();
        if let lastInterval = info[FT24HrEventKey.dateKey] as? TimeInterval {
            eventLastDate = Date(timeIntervalSinceReferenceDate: lastInterval);
        }
        if let counter = info[FT24HrEventKey.counterKey] as? Int {
            self.eventCounter = counter;
        }
    }
        
    private func eventInfo() -> [String:Any] {
        let userInfo = UserDefaults.standard.object(forKey: FT24HrEventKey.eventsInfoKey) as? [String:Any] ?? [String:Any]()
        let eventInfo = userInfo[self.eventName] as? [String:Any] ?? [String:Any]()
        return eventInfo;
    }
    
    private func updateEventInfo() {
        var userInfo = UserDefaults.standard.object(forKey: FT24HrEventKey.eventsInfoKey) as? [String:Any] ?? [String:Any]()
        var curEventInfo = userInfo[self.eventName] as? [String:Any] ?? [String:Any]()

        if let date = self.eventLastDate {
            curEventInfo[FT24HrEventKey.dateKey] = date.timeIntervalSinceReferenceDate;
        }
        
        if self.eventCounter > 0 {
            curEventInfo[FT24HrEventKey.counterKey] = self.eventCounter;
        }
        else {
            curEventInfo.removeValue(forKey: FT24HrEventKey.counterKey)
        }
        
        userInfo[self.eventName] = curEventInfo;
        UserDefaults.standard.setValue(userInfo, forKey: FT24HrEventKey.eventsInfoKey);
    }
    
    func trackEvent(_ params: [String:Any]? = nil) {
        var shouldLog = true;
                
        let curDate = Date()
        if let lastDate = self.eventLastDate, lastDate.daysBetween(date: curDate) < 1 {
            shouldLog = false;
        }
        
        self.eventCounter += 1;
        if shouldLog, self.eventCounter >= self.maxCounter {
            self.eventLastDate = curDate;
            self.eventCounter = 0;

            track(self.eventName,
                  params: params,
                  screenName: self.screenName,
                  shouldLog: false);
        }
        self.eventCounter = min(self.eventCounter,maxCounter);
        self.updateEventInfo();
    }
}
