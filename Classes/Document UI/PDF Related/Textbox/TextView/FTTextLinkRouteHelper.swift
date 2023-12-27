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
    
    static func getQueryItems(of url: URL) -> (docId: String?, pageId: String?) {
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        let documentId = queryItems?.first(where: { $0.name == "documentId" })?.value
        let pageId = queryItems?.first(where: { $0.name == "pageId" })?.value
        return (docId: documentId, pageId: pageId)
    }
}
