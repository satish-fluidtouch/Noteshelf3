//
//  FTFavoriteEditViewController.swift
//  Noteshelf3
//
//  Created by Narayana on 03/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon
import SwiftUI

protocol FTFavoriteEditDelegate: NSObjectProtocol {
    func didChangeFavorite(_ penset: FTPenSetProtocol)
    func didDeleteFavorite(_ favorite: FTPenSetProtocol)
    func didDismissEditModeScreen()
}

class FTFavoriteEditViewController: UIViewController, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()
    static let contentSize = CGSize(width: 340, height: 410)

    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var segmentControl: UISegmentedControl!
    @IBOutlet private weak var topConstraint: NSLayoutConstraint?

    private var sizeEditController: FTFavoriteSizeEditController?
    private var colorEditController: FTFavoriteColorEditController?
    private var penTypeEditController: FTFavoritePenTypeEditController?

    weak var delegate: FTFavoriteEditDelegate?
    var favorite: FTPenSetProtocol!
    var manager: FTFavoritePensetManager!
    var activity: NSUserActivity?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addPenSizeColorEditViews()
        self.configureSegmentControl()
        let placement = FTShortcutPlacement.getSavedPlacement()
        if placement.isHorizantalPlacement() {
            self.topConstraint?.constant = 16.0
        } else {
            self.topConstraint?.constant = 6.0
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.delegate = self
    }

    deinit {
        self.delegate?.didDismissEditModeScreen()
    }

    func getCurrentSelectedSegment() -> FTFavoriteRackSegment {
        var value = FTFavoriteRackSegment.pen
        if self.favorite.type.rackType == .highlighter {
            value = FTFavoriteRackSegment.highlighter
        }
        return value
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "FTFavoritePenTypeEditController", let penTypeEditVc = segue.destination as? FTFavoritePenTypeEditController {
            penTypeEditVc.delegate = self
            self.penTypeEditController = penTypeEditVc
        }
    }

    @IBAction private func eyeDropperTapped(_ sender: Any) {
        self.showEyeDropper()
    }

    @IBAction private func deleteTapped(_ sender: Any) {
        let alert = UIAlertController(title: "DeleteFavoriteAlertTitle".localized, message: "DeleteFavoriteAlertMessage".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes".localized, style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.delegate?.didDeleteFavorite(favorite)
            self.dismiss(animated: false, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "No".localized, style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    @objc func segmentChanged() {
        var type = FTFavoriteRackSegment.pen
        if segmentControl.selectedSegmentIndex == 1 {
            type = .highlighter
        }
        let currentPenset = self.manager.fetchCurrentPenset(for: type)
        self.favorite = currentPenset
        self.delegate?.didChangeFavorite(self.favorite)
        self.manager.saveCurrentSelection(penSet: self.favorite)
        self.penTypeEditController?.reloadPenTypes()
        self.colorEditController?.remove()
        self.sizeEditController?.remove()
        self.addPenSizeColorEditViews()
    }
}

private extension FTFavoriteEditViewController {
    func showEyeDropper() {
        let controller = self.presentingViewController
        let presetVm = self.colorEditController?.viewModel
        if let presentingVc = controller {
            self.dismiss(animated: true) {
                if let favBarVc = self.delegate as? FTFavoritebarViewController {
                    favBarVc.presetViewModel = presetVm
                    FTColorEyeDropperPickerController.showEyeDropperOn(presentingVc,delegate: favBarVc)
                }
            }
        }
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
        let viewModel = FTFavoritePresetsViewModel(segment: self.getCurrentSelectedSegment(), currentSelectedColor: self.favorite.color, userActivity: self.activity)
        viewModel.createEditDelegate(self)
        let colorController = FTFavoriteColorEditController(viewModel: viewModel)
        colorController.delegate = self
        self.add(colorController)
        colorController.view.translatesAutoresizingMaskIntoConstraints = false
        let left = colorController.view.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16)
        let right = colorController.view.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16)
        let bottom = colorController.view.bottomAnchor.constraint(equalTo: sizeController.view.topAnchor, constant: 0)
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

extension FTFavoriteEditViewController: FTFavoriteSizeUpdateDelegate, FTFavoriteColorUpdateDelegate, FTFavoritePenTypeUpdateDelegate {
    func didChangeSize(_ size: CGFloat) {
        if let penSize = FTPenSize(rawValue: Int(size)) {
            self.favorite.size = penSize
            self.favorite.preciseSize = size
            self.manager.saveCurrentSelection(penSet: self.favorite)
            self.delegate?.didChangeFavorite(self.favorite)
        }
    }

    func didChangeColor(_ color: String) {
        self.favorite.color = color
        self.manager.saveCurrentSelection(penSet: self.favorite)
        self.penTypeEditController?.reloadPenTypes()
        self.delegate?.didChangeFavorite(self.favorite)
    }

    func didChangePenType(_ type: FTPenType) {
        self.favorite.type = type
        self.manager.saveCurrentSelection(penSet: self.favorite)
        self.delegate?.didChangeFavorite(self.favorite)
    }
}

extension FTFavoriteEditViewController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is FTFavoriteEditViewController {
            navigationController.setNavigationBarHidden(true, animated: false)
        } else {
            navigationController.setNavigationBarHidden(false, animated: false)
        }
    }
}

extension FTFavoriteEditViewController: FTFavoritePresetEditDelegate {
    func didTapEyeDropper() {
        self.showEyeDropper()
    }
}
