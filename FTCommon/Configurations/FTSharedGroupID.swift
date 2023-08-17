//
//  FTSharedGroupID.swift
//  Noteshelf
//
//  Created by Amar on 05/09/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
@objc public class FTSharedGroupID: NSObject {
    @objc public static func getAppGroupID() -> String {
#if DEBUG
        return "group.com.fluidtouch.noteshelf3-dev"
#elseif BETA
        return "group.com.fluidtouch.noteshelf3-beta"
#else
        return "group.com.fluidtouch.noteshelf"
#endif
    }

public static func getAppGroupIdForNS1Migration() -> String {
#if DEBUG
        return "group.com.fluidtouch.noteshelf-1to2-migration-dev"
#elseif BETA
        return "group.com.fluidtouch.noteshelf-1to2-migration-beta"
#else
        return "group.com.fluidtouch.noteshelf-1to2-migration"
#endif
    }
}
