//
//  FTResourceFetcher.swift
//  Noteshelf3
//
//  Created by Narayana on 06/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTResourceFetcher: NSObject {
    var request: NSBundleResourceRequest?

    init(tags: Set<String>) {
        request = NSBundleResourceRequest(tags: tags)
        request?.loadingPriority = NSBundleResourceRequestLoadingPriorityUrgent
    }

    func fetchResources(onCompletion: @escaping (Error?) -> Void) {
        request?.beginAccessingResources(completionHandler: { error in
            onCompletion(error)
        })
    }

    func endAccessingResources() {
        request?.endAccessingResources()
    }
}
