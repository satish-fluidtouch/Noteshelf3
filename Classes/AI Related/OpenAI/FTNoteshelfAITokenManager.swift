//
//  FTNoteshelfAITokenManager.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 06/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTNoteshelfAITokenManager: NSObject,ObservableObject {
    static let shared = FTNoteshelfAITokenManager();
    var maxAllowedTokens: Int {
        return 100;
    }
    
    func markAsConsumed() {
        let consumed = UserDefaults.standard.integer(forKey: "aiTokensConsumed");
        UserDefaults.standard.set(consumed+1, forKey: "aiTokensConsumed");
    }
    
    var consumedTokens: Int {
        return UserDefaults.standard.integer(forKey: "aiTokensConsumed");
    }
    
    var tokensLeft: Int {
        return (self.maxAllowedTokens - self.consumedTokens);
    }
    
#if !RELEASE
    func resetAITokens() {
        UserDefaults.standard.removeObject(forKey: "aiTokensConsumed");
    }
#endif
}
