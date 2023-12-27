//
//  NSUbiquitousKeyValueStore_AIToken.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 09/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTUbiquitousKeyValueStoreListner: NSObject {
    private static let sharedOmstamce = FTUbiquitousKeyValueStoreListner();
    static func shared() -> FTUbiquitousKeyValueStoreListner {
        return sharedOmstamce;
    }
    
    override init() {
        super.init();
        NotificationCenter.default.addObserver(self, selector: #selector(self.didChangeUbiquityStore(_:)), name: .NSUbiquityIdentityDidChange, object: nil);
    }
    
    @objc private func didChangeUbiquityStore(_ notifcation: Notification) {
        let deviceInfo = self.deviceIdsForFabric();
        if !deviceInfo.isEmpty {
            FabricHelper.updateFabric(key: FabircKeys.DeviceIDs, value: deviceInfo);
        }
    }
    
    private var keyStore: NSUbiquitousKeyValueStore {
        return NSUbiquitousKeyValueStore.default;
    }
    
    func deviceIds() -> [String] {
        var devices: [String] = [String]()
        let ids = self.deviceIDs();
        ids.forEach { eachItem in
            devices.append(eachItem.key);
        }
        return devices;
    }
    
    func deviceIdsForFabric() -> String {
        var stringToReturn: String = ""
        let ids = self.deviceIDs()
        ids.forEach { eachItem in
            stringToReturn.append("\(eachItem.key): \(eachItem.value) ");
        }
        return stringToReturn;
    }
    
    private func deviceIDs() -> [String: String] {
        return keyStore.dictionary(forKey: "DeviceIDs") as? [String: String] ?? [String: String]();
    }
    
    func addUserID(_ userID: String) {
        var storedIDs = self.deviceIDs();
        if storedIDs[userID] == nil {
            storedIDs[userID] = FTUtils.deviceModel();
            keyStore.set(storedIDs, forKey: "DeviceIDs");
            keyStore.synchronize();
        }
    }
}

extension NSUbiquitousKeyValueStore {
    static func tokenInfo() -> FTAITokenInfo? {
        let ubiquityValueStore = NSUbiquitousKeyValueStore.default;
        if let data = ubiquityValueStore.data(forKey: "AI-Token-Info") {
            do {
                if let info = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String:Any] {
                    let token = FTAITokenInfo(with: info);
                    return token;
                }
            }
            catch {
                
            }
        }
        return nil;
    }
    
    static func saveTokenInfo(_ tokenInfo: FTAITokenInfo) {
        do {
            let ubiquityValueStore = NSUbiquitousKeyValueStore.default;
            let info = try PropertyListSerialization.data(fromPropertyList: tokenInfo.dictInfo, format: .binary, options:0)
            ubiquityValueStore.set(info, forKey: "AI-Token-Info");
            ubiquityValueStore.synchronize();
        }
        catch {
            
        }
    }
}
