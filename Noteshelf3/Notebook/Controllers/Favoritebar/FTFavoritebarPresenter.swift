//
//  FTFavoritebarPresenter.swift
//  Noteshelf3
//
//  Created by Narayana on 26/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

private let favBarSize = CGSize(width: 293.0, height: 38.0)

@objcMembers class FTFavoritebarPresenter: FTShortcutBasePresenter {
    private(set) weak var parentVC: UIViewController?
    private(set) weak var favoriteBarVC: FTFavoritebarViewController?

    var favoriteBar: UIView? {
        return self.favoriteBarVC?.view
    }

    func showFavoriteToolbar(on viewController: UIViewController) {
        viewController.children
            .filter { $0 is FTFavoritebarViewController }
            .forEach { $0.remove() }

        self.parentVC = viewController
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: FTFavoritebarViewController.self))
        guard let controller  = storyboard.instantiateViewController(withIdentifier: "FTFavoritebarViewController") as? FTFavoritebarViewController else {
            fatalError("Proggrammer error")
        }
        self.favoriteBarVC = controller
        viewController.add(controller)
        self.favoriteBar?.frame.size = favBarSize
//        let reqCenter = self.shortcutViewCenter(for: .top, size: favBarSize)
        self.self.favoriteBar?.center = CGPoint(x: viewController.view.frame.width/2, y: 150.0)
    }
}
