//
//  FTStoreActionManager.swift
//  TempletesStore
//
//  Created by Siva on 08/03/23.
//

import Foundation
import Combine
import UIKit

enum FTStoreActions {
    case didTapOnDiscoveryItem(items: [TemplateInfo], selectedIndex: Int)
}

enum FTStoreContainerActions {
    case createNotebookForTemplate(url: URL, isLandscape: Bool, isDark: Bool)
    case createNotebookForDairy(fileName: String, title: String, startDate: Date, endDate: Date, coverImage: UIImage, isLandScape: Bool)
    case createNotebookFor(url: URL)
}

final class FTStoreActionManager {
    var actionStream = PassthroughSubject<FTStoreActions, Never>()
    var containerActions = PassthroughSubject<FTStoreContainerActions, Never>()
    var cancellables = Set<AnyCancellable>()
}
