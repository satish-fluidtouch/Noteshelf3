//
//  FTNoteshelfAITokenManager.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 06/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework
import Combine

class FTNoteshelfAIConfigHelper: NSObject {
    static func configureAI() {
        FTDigitalInkRecognitionManager.shared.configure();
        FTNoteshelfAITokenManager.shared.configure();
    }
}

class FTNoteshelfAITokenManager: NSObject,ObservableObject {
    static let shared = FTNoteshelfAITokenManager();
    private var storedTokenInfo = FTAITokenInfo();
    private var premiumCancellable : AnyCancellable?;
    
    func configure() {
        self.refreshTokenInfo();
        self.configureForPremoumUser();
        if !FTIAPManager.shared.premiumUser.isPremiumUser {
            premiumCancellable = FTIAPManager.shared.premiumUser.$isPremiumUser.sink { [weak self] isPremiumUser in
                if isPremiumUser {
                    self?.configureForPremoumUser();
                    self?.premiumCancellable?.cancel();
                    self?.premiumCancellable = nil;
                }
            }
        }
    }
    
    deinit {
        premiumCancellable?.cancel();
        premiumCancellable = nil;
    }
    
    var maxAllowedTokens: Int {
#if DEBUG
        return 15;
#else
        if FTIAPManager.shared.premiumUser.isPremiumUser {
            return 100;
        }
        return 30;
#endif
    }
    
    func markAsConsumed() {
        storedTokenInfo.consumedToken += 1;
        self.saveTokenInfo();
    }
    
    var consumedTokens: Int {
        if Date.utcDate.compareDate(storedTokenInfo.lastResetDate) == .orderedAscending {
            return self.maxAllowedTokens;
        }
        return storedTokenInfo.consumedToken
    }
    
    var tokensLeft: Int {
        return (self.maxAllowedTokens - self.consumedTokens);
    }
    
#if DEBUG
    func resetAITokens() {
        KeychainItemWrapper.resetKeyChain();
        UserDefaults.standard.removeObject(forKey: "prev_request_date");
    }
#endif
    
    func daysLeftForTokenReset() -> Int {
        let currentDate = Date.utcDate;
        let resetDate = storedTokenInfo.lastResetDate;
        let nextMonth = resetDate.nextMonth.startDayOfMonth();

        let daysLeft = nextMonth.daysBetween(date: currentDate);
        return daysLeft;
    }
    
    func refreshTokenInfo() {
        self.storedTokenInfo = tokeknInfo();
    }
}

private extension FTNoteshelfAITokenManager {
    private func saveTokenInfo() {
        KeychainItemWrapper.saveTokenInfo(storedTokenInfo);
//        NSUbiquitousKeyValueStore.saveTokenInfo(storedTokenInfo)
    }
    
    private func tokeknInfo() -> FTAITokenInfo {
        if let tokenInfo = KeychainItemWrapper.tokenInfo() {
            return tokenInfo;
        }
//        else if let tokenInfo = NSUbiquitousKeyValueStore.tokenInfo() {
//            return tokenInfo;
//        }
        return FTAITokenInfo();
    }
    
    @objc private func resetTokenIfNeeded(_ notification: Notification?) {
        self.refreshTokenInfo();
        if shouldCheckForUpdate() {
            let lastResetDate = storedTokenInfo.lastResetDate;
            let currentDate = Date.utcDate;
            if lastResetDate.month() < currentDate.month()
                || lastResetDate.year() < currentDate.year() {
                storedTokenInfo.reset();
                self.saveTokenInfo();
                UserDefaults.standard.set(storedTokenInfo.lastResetDate.utcDateString, forKey: "prev_request_date");
            }
        }
    }
    
    private func shouldCheckForUpdate() -> Bool {
        guard FTIAPManager.shared.premiumUser.isPremiumUser else {
            return false;
        }
        
        let currentDate = Date.utcDate;
        var previousReqDate: Date?;
        if let previousReqDateStr = UserDefaults.standard.string(forKey: "prev_request_date") {
            previousReqDate = Date.dateFromUTC(previousReqDateStr);
        }
        var shouldProceed = false;
        if(nil == previousReqDate) {
            shouldProceed = true;
        }
        
        if let _prevDate = previousReqDate
            , currentDate.compareDate(_prevDate) == ComparisonResult.orderedDescending {
            shouldProceed = true;
        }
        return shouldProceed;
    }
    
    func configureForPremoumUser() {
        if FTIAPManager.shared.premiumUser.isPremiumUser {
            self.addObservers();
            self.resetTokenIfNeeded(nil);
        }
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.resetTokenIfNeeded(_:)), name: UIApplication.didBecomeActiveNotification, object: nil);
    }
}

//private extension FTNoteshelfAITokenManager {
//    func getCurrentUTCTime(completion: @escaping (Date?) -> Void) {
//        let url = URL(string: "http://worldclockapi.com/api/json/utc/now")! // Replace with your preferred time API
//        
//        let task = URLSession.shared.dataTask(with: url) { data, response, error in
//            if let error = error {
//                print("Error: \(error.localizedDescription)")
//                completion(nil)
//                return
//            }
//            
//            if let data = data {
//                do {
//                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                       let dateString = json["currentDateTime"] as? String {
//                        let dateFormatter = DateFormatter()
//                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
//                        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
//                        
//                        if let date = dateFormatter.date(from: dateString) {
//                            completion(date)
//                        } else {
//                            completion(nil)
//                        }
//                    }
//                } catch {
//                    print("Error parsing JSON: \(error.localizedDescription)")
//                    completion(nil)
//                }
//            }
//        }
//        task.resume()
//    }
//}
