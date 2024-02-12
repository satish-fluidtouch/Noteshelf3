//
//  FTTextLinkRouteHelper.swift
//  Noteshelf3
//
//  Created by Narayana on 22/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import FTCommon

extension URL {
    init?(docId: String, pageId: String) {
        var components = URLComponents()
        components.scheme = FTSharedGroupID.getAppBundleID()
        components.path = FTAppIntentHandler.hyperlinkPath
        components.queryItems = [
            URLQueryItem(name: "documentId", value: docId),
            URLQueryItem(name: "pageId", value: pageId)
        ]
        guard let url = components.url else { return nil }
        self = url
    }

    func isAppLink() -> Bool {
        return self.scheme == FTSharedGroupID.getAppBundleID()
    }

    func isAppTextPageLink() -> Bool {
        return self.path().contains(FTAppIntentHandler.hyperlinkPath)
    }

    func isTemplateIntentPath() -> Bool {
        return self.path().contains(FTAppIntentHandler.templatesPath)
    }

    func getQueryItems() -> (docId: String?, pageId: String?) {
        let queryItems = URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems
        let documentId = queryItems?.first(where: { $0.name == "documentId" })?.value
        let pageId = queryItems?.first(where: { $0.name == "pageId" })?.value
        return (docId: documentId, pageId: pageId)
    }
}
