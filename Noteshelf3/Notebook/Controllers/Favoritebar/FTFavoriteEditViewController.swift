//
//  FTFavoriteEditViewController.swift
//  Noteshelf3
//
//  Created by Narayana on 03/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

protocol FTFavoriteEditDelegate: NSObjectProtocol {
    func didChangeFavorite(_ penset: FTPenSetProtocol)
}

class FTFavoriteEditViewController: UIViewController, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()
    static let contentSize = CGSize(width: 340, height: 410)
  
    var favorite: FTPenSetProtocol = FTDefaultPenSet()
    private var sizeEditController: FTFavoriteSizeEditController?
    private var colorEditController: FTFavoriteColorEditController?

    weak var delegate: FTFavoriteEditDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Favorite"
        self.addNavigationItems()
        self.addPenSizeColorEditViews()
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

    func addPenSizeColorEditViews() {
        // Size edit view
        let sizeController = FTFavoriteSizeEditController(size: favorite.preciseSize, penType: favorite.type)
        sizeController.delegate = self
        self.add(sizeController)
        sizeController.view.translatesAutoresizingMaskIntoConstraints = false
        let bottomConstraint = sizeController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -16)
        let leftConstraint = sizeController.view.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16)
        let rightConstraint = sizeController.view.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16)
        NSLayoutConstraint.activate([bottomConstraint, leftConstraint, rightConstraint])
        self.sizeEditController = sizeController
        
        // Color edit view
        let colorController = FTFavoriteColorEditController(penType: favorite.type, activity: self.view.window?.userActivity)
        colorController.delegate = self
        self.add(colorController)
        colorController.view.translatesAutoresizingMaskIntoConstraints = false
        let left = colorController.view.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16)
        let right = colorController.view.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16)
        let bottom = colorController.view.bottomAnchor.constraint(equalTo: sizeController.view.topAnchor, constant: -16)
        NSLayoutConstraint.activate([left, right, bottom])
        self.colorEditController = colorController
    }


    @objc func eyeDropperTapped() {
    }

    @objc func deleteTapped() {
    }
}

extension FTFavoriteEditViewController: FTFavoriteSizeUpdateDelegate, FTFavoriteColorUpdateDelegate {
    func didChangeSize(_ size: CGFloat) {
        if let penSize = FTPenSize(rawValue: Int(size)) {
            self.favorite.size = penSize
            self.favorite.preciseSize = size
            self.delegate?.didChangeFavorite(self.favorite)
        }
    }

    func didChangeColor(_ color: String) {
        self.favorite.color = color
        self.delegate?.didChangeFavorite(self.favorite)
    }
}
