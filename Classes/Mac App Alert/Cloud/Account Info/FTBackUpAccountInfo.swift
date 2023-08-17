//
//  FTBackUpAccountInfo.swift
//  FTAutoBackupSwift
//
//  Created by Simhachalam Naidu on 13/08/20.
//  Copyright © 2020 Simhachalam Naidu. All rights reserved.
//

import UIKit

class FTBackUpAccountInfo: NSObject {
    var name: String?
    var email: String?
    var totalBytes: UInt64 = UInt64(0.0)
    var consumedBytes: UInt64 = UInt64(0.0)
    
    var percentageUsed: CGFloat {
        var percentage: CGFloat = 0.0
        let totalValue: CGFloat = CGFloat(self.totalBytes)
        let consumerValue: CGFloat = CGFloat(self.consumedBytes)
        if totalValue > 0 {
            percentage = (consumerValue / totalValue) * 100;
        }
        return percentage;
    }
}
