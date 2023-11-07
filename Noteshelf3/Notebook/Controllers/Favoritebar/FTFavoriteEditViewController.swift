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
    func didChangeRackType(_ rackType: FTRackType)
}

class FTFavoriteEditViewController: UIViewController, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()
    static let contentSize = CGSize(width: 340, height: 410)
  
    @IBOutlet private weak var segmentControl: UISegmentedControl!

    private var sizeEditController: FTFavoriteSizeEditController?
    private var colorEditController: FTFavoriteColorEditController?
    private var penTypeEditController: FTFavoritePenTypeEditController?

    weak var delegate: FTFavoriteEditDelegate?
    var rack = FTRackData(type: .pen, userActivity: nil)

    private var favorite: FTPenSetProtocol {
        self.rack.currentPenset
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addPenSizeColorEditViews()
        self.configureSegmentControl()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "FTFavoritePenTypeEditController", let penTypeEditVc = segue.destination as? FTFavoritePenTypeEditController {
            penTypeEditVc.rack = self.rack
            self.penTypeEditController = penTypeEditVc
        }
    }

    @IBAction private func eyeDropperTapped(_ sender: Any) {
    }

    @IBAction private func deleteTapped(_ sender: Any) {
    }

    @objc func segmentChanged() {
        var type = FTRackType.pen
        if segmentControl.selectedSegmentIndex == 1 {
            type = .highlighter
        }
        self.delegate?.didChangeRackType(type)
        self.penTypeEditController?.reloadPenTypes()
        self.colorEditController?.remove()
        self.sizeEditController?.remove()
        self.addPenSizeColorEditViews()
    }
}

private extension FTFavoriteEditViewController {
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

    func configureSegmentControl() {
        self.segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        if favorite.type.rackType == .highlighter {
            self.segmentControl.selectedSegmentIndex = 1
        } else {
            self.segmentControl.selectedSegmentIndex = 0
        }
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
        self.penTypeEditController?.reloadPenTypes()
        self.delegate?.didChangeFavorite(self.favorite)
    }
}
