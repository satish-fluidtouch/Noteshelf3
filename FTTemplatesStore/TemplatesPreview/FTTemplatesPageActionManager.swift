//
//  FTTemplatesPageActionManager.swift
//  TempletesStore
//
//  Created by Siva on 08/03/23.
//

import UIKit
import Combine

enum TemplatesPageActions {
    case pageOrientationChange(segment: UISegmentedControl)
    case createNotebook
    case addToFavorite
}

enum TemplatesPageRefresh {
    case refresh
}

final class FTTemplatesPageActionManager {
    static let shared = FTTemplatesPageActionManager()
    private init() {}
    var actionStream = PassthroughSubject<TemplatesPageActions, Never>()
    var isFavourate = PassthroughSubject<Bool, Never>()

    var cancellables = Set<AnyCancellable>()
}
