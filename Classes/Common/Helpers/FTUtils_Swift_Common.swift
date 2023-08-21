//
//  FTUtils_Swift_Common.swift
//  Noteshelf
//
//  Created by Akshay on 26/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

extension FTUtils {
    @objc class func getGroupId() -> String {
        FTSharedGroupID.getAppGroupID()
    }

    class func getAppVersionInfo() -> String {
        var versionString = String(format: NSLocalizedString("VersionNumber", comment: "VERSION %@"), appVersion())
        let buildNumber = appBuildVersion()
        if(buildNumber != "EMPTY")
        {
            versionString += " (\(buildNumber))"
        }
        return versionString
    }
}
