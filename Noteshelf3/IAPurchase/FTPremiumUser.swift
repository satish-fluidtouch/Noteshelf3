//
//  FTPremiumUser.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 09/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftUI

public enum FTPremiumUserError: Error {
    case nonPremiumError
}

public class FTPremiumUser: ObservableObject {
    @Published public var isPremiumUser = false;
    @Published public var numberOfBookCreate: Int = 0;
    @Published public var maxBookLimitForFree: Int = 3;

    public init() {

    }
    
    public var nonPremiumQuotaReached: Bool {
        if isPremiumUser {
            return false;
        }
        return numberOfBookCreate >= maxBookLimitForFree;
    }

    public func canAddFewMoreBooks(count: Int) -> Bool {
        var canAddFewMore = false
        let upcomingBookCount = self.numberOfBookCreate + count
        if isPremiumUser {
            canAddFewMore = true
        } else if upcomingBookCount <= self.maxBookLimitForFree {
            canAddFewMore = true
        }
        return canAddFewMore
    }
}
