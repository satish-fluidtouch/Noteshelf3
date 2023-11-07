//
//  FTFavoriteShortcutController.swift
//  Noteshelf3
//
//  Created by Narayana on 03/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTFavoriteShortcutViewController: UIViewController {
    weak var favbarVc: FTFavoritebarViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.autoresizingMask = UIView.AutoresizingMask(rawValue: 0)
        self.view.backgroundColor = .clear
    }

    func addFavoritesView(userActivity: NSUserActivity?) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: FTFavoritebarViewController.self))
        guard let controller  = storyboard.instantiateViewController(withIdentifier: "FTFavoritebarViewController") as? FTFavoritebarViewController else {
            fatalError("Proggrammer error")
        }
        controller.activity = userActivity
        self.favbarVc = controller
        self.add(controller, frame: self.view.bounds)
    }

    func handleEndMovement() {
        self.favbarVc?.reloadFavoritesData()
    }
}
