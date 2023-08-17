//
//  FTSharedGroupID.swift
//  Noteshelf
//
//  Created by Amar on 05/09/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objc class FTSharedGroupID: NSObject {
    @objc static func getAppGroupID() -> String
    {
        #if DEBUG
        return "group.com.fluidtouch.noteshelf-dev"
        #elseif BETA
        return "group.com.fluidtouch.noteshelf3-beta"
        #else
        return "group.com.fluidtouch.noteshelf3"
        #endif
    }
    
    static func getAppGroupIdForNS1Migration() -> String
    {
        #if DEBUG
        return "group.com.fluidtouch.noteshelf-1to2-migration-dev"
        #elseif BETA
        return "group.com.fluidtouch.noteshelf-1to2-migration-beta"
        #else
        return "group.com.fluidtouch.noteshelf-1to2-migration"
        #endif
    }
}
