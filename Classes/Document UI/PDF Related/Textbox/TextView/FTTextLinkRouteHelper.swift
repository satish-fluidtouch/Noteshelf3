//
//  FTTextLinkRouteHelper.swift
//  Noteshelf3
//
//  Created by Narayana on 22/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTTextLinkRouteHelper: NSObject {
    static func getLinkUrlForTextView(using docId: String, pageId: String) -> URL? {
        var components = URLComponents()
        components.scheme = FTSharedGroupID.getAppBundleID()
        components.path = FTAppIntentHandler.hyperlinkPath
        components.queryItems = [
            URLQueryItem(name: "documentId", value: docId),
            URLQueryItem(name: "pageId", value: pageId)
        ]
        return components.url
    }
}
