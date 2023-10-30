//
//  NSUbiquitousKeyValueStore_AIToken.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 09/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

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
