//
//  FTAnalytics_Extention.swift
//  Noteshelf3
//
//  Created by Siva on 23/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

public struct ScreenName {
}

public struct EventName {

}

// FTParameters Events & Values
public struct EventParameterKey {
    public static let location = "location"
    public static let title = "title"
    public static let tool = "tool"
    public static let slot = "slot"
    static let count = "count"
    static let origin = "origin"
    static let toggle = "toggle"
    static let source = "source"
    static let status = "status"
    static let swipe = "swipe"
    public static let orientation = "orientation"
}

public struct EventParameterValue {
    static let unSplash = "Unsplash"
    static let photoLibrary = "PhotoLibrary"
    static let remote = "Remote"
    static let on = "on"
    static let off = "off"
    static let success = "success"
    static let fail = "fail"
    static let audio = "audio"
    static let scan = "scan"
    static let browse = "browse"
    public static let potrait = "potrait"
    public static let landscape = "landscape"

}
