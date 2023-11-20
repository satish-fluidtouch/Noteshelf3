//
//  FTToolTypeShortcutViewController.swift
//  Noteshelf3
//
//  Created by Narayana on 29/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

protocol FTShorctcutActionDelegate: AnyObject {
    func didTapPresentationOption(_ option: FTPresenterModeOption)
    func didChangeCurrentPenset(_ penset: FTPenSetProtocol)
    func showSizeEditView(position: FavoriteSizePosition, viewModel: FTFavoriteSizeViewModel);
    func removeSizeEditViewController();
}

protocol FTShapeSelectDelegate: AnyObject {
    func didSelectShape(shape: FTShapeType)
    func saveFavoriteShapes()
}

class FTToolTypeShortcutViewController: UIViewController, FTViewControllerSupportsScene {
    var addedObserverOnScene: Bool = false
    weak var delegate: FTShorctcutActionDelegate?
    
    private weak var colorModel: FTFavoriteColorViewModel?
    private weak var shapeModel: FTFavoriteShapeViewModel?
    // Don't make below viewmodel weak as this is needed for eyedropper delegate to implemented here(since we are dismissing color edit controller)
    private var penShortcutViewModel: FTPenShortcutViewModel?

    private var rackType: FTRackType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.translatesAutoresizingMaskIntoConstraints = false;
        self.view.autoresizingMask = UIView.AutoresizingMask(rawValue: 0);
        self.view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
#if targetEnvironment(macCatalyst)
        self.configureSceneNotification()
#endif
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
#if targetEnvironment(macCatalyst)
        self.dismissPresentedPopoverIfExists()
#endif
    }

    func showShortcutViewWrto(rack: FTRackData) {
        self.rackType = rack.type
        if rack.type == .pen || rack.type == .highlighter {
            let _colorModel =
            FTFavoriteColorViewModel(rackData: rack, delegate: self, scene: self.view?.window?.windowScene)
            let sizeModel =
            FTFavoriteSizeViewModel(rackData: rack, delegate: self, scene: self.view?.window?.windowScene)
            let shortcutView = FTPenShortcutView(colorModel: _colorModel, sizeModel: sizeModel)
            let hostingVc = FTPenShortcutHostingController(rootView: shortcutView)
            self.add(hostingVc, frame: self.view.bounds)
            self.colorModel = _colorModel;
        } else if rack.type == .shape {
            let _colorModel =
            FTFavoriteColorViewModel(rackData: rack, delegate: self, scene: self.view?.window?.windowScene)
            let sizeModel =
            FTFavoriteSizeViewModel(rackData: rack, delegate: self, scene: self.view?.window?.windowScene)
            let _shapeModel = FTFavoriteShapeViewModel(rackData: rack, delegate: self)
            let shortcutView = FTShapeShortcutView(shapeModel: _shapeModel, colorModel: _colorModel, sizeModel: sizeModel)
            let hostingVc = FTShapeShortcutHostingController(rootView: shortcutView)
            self.add(hostingVc, frame: self.view.bounds)
            self.colorModel = _colorModel;
            self.shapeModel = _shapeModel;
        } else if rack.type ==  .presenter {
            let viewModel = FTPresenterShortcutViewModel(rackData: rack, delegate: self)
            let shortcutView = FTPresenterShortcutView(viewModel: viewModel)
            let hostingVc = FTPresenterShortcutHostingController(rootView: shortcutView)
            self.add(hostingVc, frame: self.view.bounds)
        }
    }
}


extension FTToolTypeShortcutViewController: FTFavoriteColorEditDelegate {
    func showEditColorScreen(using rack: FTRackData, position: FavoriteColorPosition) {
        self.removeSizeEditViewIfNeeded()
        let viewModel = FTPenShortcutViewModel(rackData: rack)
        let hostingVc = FTPenColorEditController(viewModel: viewModel, delegate: self)
        self.penShortcutViewModel = viewModel
        let flow = FTColorsFlowType.penType(rack.currentPenset.type)
        let editMode = FTPenColorSegment.savedSegment(for: flow)
        var contentSize = FTPenColorEditController.presetViewSize
        if editMode == .grid {
            contentSize = FTPenColorEditController.gridViewSize
        }
        var arrowOffset: CGFloat = 0.0
        let step: CGFloat = 32.0
        self.view.transform = .identity
        var rect: CGRect = self.view.bounds
        // To position the arrow correctly from swiftUI view while presenting the popover
        // Better solution would be appericiated
        if rack.type == .pen || rack.type == .highlighter {
            arrowOffset = 10.0
            if position == .third {
                arrowOffset += step
            } else if position == .second {
                arrowOffset += (2 * step)
            } else if position == .first {
                arrowOffset += (3 * step)
            }
        } else if rack.type == .shape {
            arrowOffset = 15.0
            if position == .second {
                arrowOffset -= step
            } else if position == .third {
                arrowOffset -= (2 * step)
            } else if position == .custom {
                arrowOffset -= (3 * step)
            }
        }
        rect.origin.x -=  arrowOffset
        let placement = FTShortcutPlacement.getSavedPlacement()
        var arrowDirections: UIPopoverArrowDirection = .any
        if placement == .top {
            arrowDirections = [UIPopoverArrowDirection.up]
        } else if placement == .bottom {
            arrowDirections = [UIPopoverArrowDirection.down]
        } else {
            self.view.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
            arrowDirections = [UIPopoverArrowDirection.left, UIPopoverArrowDirection.right]
        }
        hostingVc.ftPresentationDelegate.source = self.view
        hostingVc.ftPresentationDelegate.sourceRect = rect
        hostingVc.ftPresentationDelegate.permittedArrowDirections = arrowDirections
        self.ftPresentPopover(vcToPresent: hostingVc, contentSize: contentSize, hideNavBar: true)
    }
}

extension FTToolTypeShortcutViewController: FTFavoriteColorNotifier {
    func didSelectColorFromEditScreen(_ penset: FTPenSetProtocol) {
        self.colorModel?.updateFavoriteColor(with: penset.color)
        self.delegate?.didChangeCurrentPenset(penset)
    }

    func saveFavoriteColorsIfNeeded() {
        self.colorModel?.updateCurrentFavoriteColors()
    }
}

extension FTToolTypeShortcutViewController: FTFavoriteSelectDelegate {
    func didChangeCurrentPenset(_ penset: FTPenSetProtocol, dismissSizeEditView: Bool) {
        if dismissSizeEditView {
            self.removeSizeEditViewIfNeeded()
        }
        self.delegate?.didChangeCurrentPenset(penset)
    }
}

extension FTToolTypeShortcutViewController: FTFavoriteSizeEditDelegate {
    func showSizeEditScreen(position: FavoriteSizePosition, viewModel: FTFavoriteSizeViewModel) {
        if let windowParent = self.view.window {
            self.removeSizeEditViewIfNeeded()
            let hostingVc = FTPenSizeEditController(viewModel: viewModel, editPosition: position)
            hostingVc.view.backgroundColor = .systemBackground
            if windowParent.frame.size.width > minScreenWidthForPopover {
                self.delegate?.showSizeEditView(position: position, viewModel: viewModel)
            } else {
                // compact mode
                self.ftPresentPopover(vcToPresent: hostingVc, contentSize: CGSize(width: 250.0, height: 150.0))
            }
        }
    }

    private func removeSizeEditViewIfNeeded() {
        self.delegate?.removeSizeEditViewController()
    }
}

extension FTToolTypeShortcutViewController: FTShapeShortcutEditDelegate {
    func showShapeEditScreen(position: FavoriteShapePosition) {
        self.removeSizeEditViewIfNeeded()
        var arrowOffset: CGFloat = 125.0
        let step: CGFloat = 32.0
        if position == .second {
            arrowOffset -= step
        } else if position == .third {
            arrowOffset -= (2 * step)
        }
        self.view.transform = .identity
        var rect = self.view.bounds
        rect.origin.x -= arrowOffset
        let placement = FTShortcutPlacement.getSavedPlacement()
        var arrowDirections: UIPopoverArrowDirection = .any
        if placement == .top {
            arrowDirections = [UIPopoverArrowDirection.up]
        } else if placement == .bottom {
            arrowDirections = [UIPopoverArrowDirection.down]
        } else {
            self.view.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
            arrowDirections = [UIPopoverArrowDirection.left, UIPopoverArrowDirection.right]
        }
        let controller = FTShapesRackViewController.showPopOver(presentingController: self, sourceView: self.view as Any, sourceRect: rect, arrowDirections: arrowDirections) as? FTShapesRackViewController
        controller?.shapeEditDelegate = self
    }

    func didSelectFavoriteShape(_ shape: FTShapeType) {
        self.removeSizeEditViewIfNeeded()
        self.shapeModel?.updateCurrentFavoriteShape(shape)
    }
}

extension FTToolTypeShortcutViewController: FTShapeSelectDelegate {
    func didSelectShape(shape: FTShapeType) {
        if let viewModel = self.shapeModel {
            viewModel.updateCurrentFavoriteShape(FTShapeType.savedShapeType())
            viewModel.editFavoriteShape(with: viewModel.currentFavoriteShape)
        }
    }
    
    func saveFavoriteShapes() {
        self.shapeModel?.saveFavoriteShapes()
    }
}

extension FTToolTypeShortcutViewController: FTPresenterShortcutDelegate {
    func didTapPresentationOption(_ option: FTPresenterModeOption) {
        self.delegate?.didTapPresentationOption(option)
    }

    func didChangeCurrentPresenterSet(_ presenterSet: FTPresenterSetProtocol) {
        self.delegate?.didChangeCurrentPenset(presenterSet)
    }
}

extension FTToolTypeShortcutViewController: FTColorEyeDropperPickerDelegate {
    func colorPicker(picker: FTColorEyeDropperPickerController,didPickColor color:UIColor) {
        if let shortcutVm = self.penShortcutViewModel {
            self.colorModel?.updateFavoriteColor(with: color.hexString)
            self.colorModel?.updateCurrentFavoriteColors()
            shortcutVm.updateCurrentSelection(colorHex: color.hexString)
            if let editIndex = shortcutVm.presetEditIndex {
                shortcutVm.updatePresetColor(hex: color.hexString, index: editIndex)
                NotificationCenter.default.post(name: .PresetColorUpdate, object: nil, userInfo: ["type": FTColorToastType.edit.rawValue])
            } else {
                shortcutVm.addSelectedColorToPresets()
                NotificationCenter.default.post(name: .PresetColorUpdate, object: nil, userInfo: ["type": FTColorToastType.add.rawValue])
            }
            shortcutVm.updateCurrentColors()
            self.delegate?.didChangeCurrentPenset(shortcutVm.currentPenset)
        }
        self.penShortcutViewModel = nil
    }
}

#if targetEnvironment(macCatalyst)
private extension FTToolTypeShortcutViewController {
    func configureSceneNotification() {
        // THis is needed when back/close of notebook is tapped, we need to close the pen color edit popover if exists(to fix memory leak caused by it)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneWillResignActive(_:)), name: UIApplication.sceneWillResignActive, object: self.sceneToObserve)
    }

    func dismissPresentedPopoverIfExists() {
        self.presentedViewController?.dismiss(animated: false)
    }

    @objc func sceneWillResignActive(_ notification: Notification) {
        if(!self.canProceedSceneNotification(notification)) {
            return
        }
        self.dismissPresentedPopoverIfExists()
    }
}
#endif
