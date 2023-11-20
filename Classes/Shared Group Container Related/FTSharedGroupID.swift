//
//  FTSharedGroupID.swift
//  Noteshelf
//
//  Created by Amar on 05/09/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

public class FTSharedGroupID {
#if ENTERPRISE_EDITION
    public static func getAppGroupID() -> String {
#if DEBUG
        return "group.com.fluidtouch.noteshelf3.enterprise-dev"
#else
        return "group.com.fluidtouch.noteshelf3.enterprise"
#endif
    }
#else
    public static func getAppGroupID() -> String {
#if DEBUG
        return "group.com.fluidtouch.noteshelf3-dev"
#elseif BETA
        return "group.com.fluidtouch.noteshelf3-beta"
#else
        return "group.com.fluidtouch.noteshelf3"
#endif
    }
#endif
    
    public static func getAppGroupIdForNS1Migration() -> String {
#if DEBUG
        return "group.com.fluidtouch.noteshelf-1to2-migration-dev"
#elseif BETA
        return "group.com.fluidtouch.noteshelf-1to2-migration-beta"
#else
        return "group.com.fluidtouch.noteshelf-1to2-migration"
#endif
    }
    
#if ENTERPRISE_EDITION
    public static func getNS2AppGroupID() -> String {
        return "group.com.fluidtouch.noteshelf"
    }
    
    public static func getAppBundleID() -> String {
#if DEBUG
        return "com.fluidtouch.noteshelf3.enterprise-dev"
#else
        return "com.fluidtouch.noteshelf3.enterprise"
#endif
    }
#else
    public static func getNS2AppGroupID() -> String {
#if DEBUG
        return "group.com.fluidtouch.noteshelf-dev"
#elseif BETA
        return "group.com.fluidtouch.noteshelf-beta"
#else
        return "group.com.fluidtouch.noteshelf"
#endif
    }
    
    public static func getAppBundleID() -> String {
#if DEBUG
        return "com.fluidtouch.noteshelf3-dev"
#elseif BETA
        return "com.fluidtouch.noteshelf3-beta"
#else
        return "com.fluidtouch.noteshelf3"
#endif
    }
#endif
    
    public static func getNS2AppBundleID() -> String {
#if DEBUG
        return "com.fluidtouch.noteshelf-dev"
#elseif BETA
        return "com.fluidtouch.noteshelf-beta"
#else
        return "com.fluidtouch.noteshelf"
#endif
    }
}
