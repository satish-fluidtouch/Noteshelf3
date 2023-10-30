//
//  KeychainItemWrapper_AIToken.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 09/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

extension KeychainItemWrapper {
#if !RELEASE
    static func resetKeyChain() {
        KeychainItemWrapper.aiTokenKeyChain()?.resetKeychainItem();
    }
#endif
    
    private static func aiTokenKeyChain() -> KeychainItemWrapper? {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            return nil;
        }
        let tokenId = bundleId.appending("-aitoken");
        return KeychainItemWrapper(identifier:tokenId , accessGroup: nil);
    }
    
    
    static func tokenInfo() -> FTAITokenInfo? {
        if let wrapper = KeychainItemWrapper.aiTokenKeyChain()
            , let value = wrapper.object(forKey: kSecValueData) as? Data {
            do {
                if let info = try PropertyListSerialization.propertyList(from: value, format: nil) as? [String:Any] {
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
        if let wrapper = KeychainItemWrapper.aiTokenKeyChain() {
            do {
                let info = try PropertyListSerialization.data(fromPropertyList: tokenInfo.dictInfo, format: .binary, options:0)
                wrapper.setObject(info, forKey: kSecValueData);
                wrapper.setObject("NSAITokenService", forKey: kSecAttrService);
            }
            catch {
                
            }
        }
    }
}
