//
//  FTStoreActionManager.swift
//  TempletesStore
//
//  Created by Siva on 08/03/23.
//

import Foundation
import Combine

enum FTStoreActions {
//    case showPreviewFor(templates: [TemplateInfo], selectedIndex: Int, type: FTStoreSectionType)
//    case navigateToCategory(template: TemplateInfo)
    case didTapOnDiscoveryItem(items: [TemplateInfo], selectedIndex: Int)
}

class FTStoreActionManager {
    static let shared = FTStoreActionManager()
    private init() {}
    var actionStream = PassthroughSubject<FTStoreActions, Never>()
    var cancellables = Set<AnyCancellable>()

}
