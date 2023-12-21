//
//  FTDocumentPageInfo.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 20/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTDocumentPageInfo : NSObject {
    var currentDate : TimeInterval?

    convenience init(currentDate : TimeInterval?){
        self.init()
        self.currentDate = currentDate
    }
}
