//
//  FTFavoriteEditViewController.swift
//  Noteshelf3
//
//  Created by Narayana on 03/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

class FTFavoriteEditViewController: UIViewController, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()

    static let contentSize = CGSize(width: 320, height: 410)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Favorite"
        self.addNavigationItems()
    }
}

private extension FTFavoriteEditViewController {
    func addNavigationItems() {
        let leftButtonImage = UIImage(systemName: "eyedropper")?.withTintColor(UIColor.appColor(.accent))
        let leftButton = UIBarButtonItem(image: leftButtonImage, style: .plain, target: self, action: #selector(eyeDropperTapped))
        navigationItem.leftBarButtonItem = leftButton
        let rightButtonImage = UIImage(systemName: "trash")?.withTintColor(UIColor.appColor(.destructiveRed))
        let rightButton = UIBarButtonItem(image: rightButtonImage, style: .plain, target: self, action: #selector(deleteTapped))
        navigationItem.rightBarButtonItem = rightButton
    }

    @objc func eyeDropperTapped() {
    }

    @objc func deleteTapped() {
    }
}
