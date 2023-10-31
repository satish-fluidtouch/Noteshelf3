//
//  FTShortcutBasePresenter.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 29/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTShortcutBasePresenter: NSObject, FTShortcutPresenterProtocol {
    weak var parentVC: UIViewController?
    weak var toolbarVc: UIViewController!
    var deskMode: RKDeskMode = .deskModePen

    var rackType: FTRackType {
        self.deskMode.rackType
    }

    // Internal variables/functions for extension purpose, not intended for out world
    internal var isMoving: Bool = false
    internal var hasAddedSlots: Bool = false
    internal var shortcutZoomMode: FTZoomShortcutMode = .auto
    internal var animDuration: CGFloat = 0.3

    var shortcutView: UIView {
        return self.toolbarVc.view
    }

    var shortcutViewPlacement: FTShortcutPlacement {
        if UIDevice.current.isIphone() {
            return .top
        }
        let placement = FTShortcutPlacement.getSavedPlacement()
        return placement
    }

    func shortcutViewSizeWrToVertcalPlacement() -> CGSize {
        var size: CGSize = .zero

        if self.deskMode == .deskModePen || self.deskMode == .deskModeMarker {
            size = penShortcutSize
        } else if self.deskMode == .deskModeShape {
            size = shapeShortcutSize
        } else if self.deskMode == .deskModeLaser {
            size = presenterShortcutSize
        } else if self.deskMode == .deskModeFavorites {
            size = CGSize(width: 293.0, height: 38.0)
        }
        return size
    }

    func configureToolbar(on viewController: UIViewController, for mode: RKDeskMode) {
        if !mode.canProceedToShowToolbar {
            return
        }
        self.deskMode = mode
        self.parentVC = viewController

        if mode != .deskModeFavorites {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: FTToolTypeShortcutViewController.self))
            guard let controller  = storyboard.instantiateViewController(withIdentifier: "FTToolTypeShortcutViewController") as? FTToolTypeShortcutViewController else {
                fatalError("Programmer error, couldnot find FTToolTypeShortcutViewController")
            }
            self.toolbarVc = controller
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: FTFavoritebarViewController.self))
            guard let controller  = storyboard.instantiateViewController(withIdentifier: "FTFavoritebarViewController") as? FTFavoritebarViewController else {
                fatalError("Proggrammer error")
            }
            self.toolbarVc = controller
        }
    }
}

protocol FTShortcutPresenterProtocol: NSObjectProtocol {
    var offset: CGFloat { get }
    var toolbarOffset: CGFloat {get set}
    var screenMode: FTScreenMode { get set }
}

extension FTShortcutPresenterProtocol {
    var offset: CGFloat {
        return 8.0
    }

    var screenMode: FTScreenMode {
        get {
            .normal
        }
        set {
            // ll be set by concrete classe if needed
        }
    }

    var toolbarOffset: CGFloat {
        get {
             FTToolbarConfig.Height.regular + offset
        } set {
            // ll be set by concrete classe if needed
        }
    }
}

private extension RKDeskMode {
    var canProceedToShowToolbar: Bool {
        var status = false
        if self == .deskModePen || self == .deskModeMarker || self == .deskModeShape || self == .deskModeLaser || self == .deskModeFavorites {
            status = true
        }
        return status
    }

    var rackType: FTRackType {
        var type = FTRackType.pen
        switch self {
        case .deskModePen:
            type = .pen
        case .deskModeMarker:
            type = .highlighter
        case .deskModeLaser:
            type = .presenter
        case .deskModeShape:
            type = .shape
        default:
            break
        }
        return type
    }
}
