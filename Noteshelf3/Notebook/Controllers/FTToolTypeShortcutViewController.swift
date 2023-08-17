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
}

protocol FTShapeSelectDelegate: AnyObject {
    func didSelectShape(shape: FTShapeType)
    func saveFavoriteShapes()
}

class FTToolTypeShortcutViewController: UIViewController {
    weak var delegate: FTShorctcutActionDelegate?

    private weak var colorModel: FTFavoriteColorViewModel?
    private weak var shapeModel: FTFavoriteShapeViewModel?
    // Don't make below viewmodel weak as this is needed for eyedropper delegate to implemented here(since we are dismissing color edit controller)
    private var penShortcutViewModel: FTPenShortcutViewModel?

    private var rackType: FTRackType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }

    func showShortcutViewWrto(rack: FTRackData) {
        self.rackType = rack.type
        if rack.type == .pen || rack.type == .highlighter {
            let _colorModel =
            FTFavoriteColorViewModel(rackData: rack, delegate: self)
            let sizeModel =
            FTFavoriteSizeViewModel(rackData: rack, delegate: self)
            let shortcutView = FTPenShortcutView(colorModel: _colorModel, sizeModel: sizeModel)
            let hostingVc = FTPenShortcutHostingController(rootView: shortcutView)
            self.add(hostingVc, frame: self.view.bounds)
            self.colorModel = _colorModel;
        } else if rack.type == .shape {
            let _colorModel =
            FTFavoriteColorViewModel(rackData: rack, delegate: self)
            let sizeModel =
            FTFavoriteSizeViewModel(rackData: rack, delegate: self)
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
        var rect = self.view.bounds
        rect.origin.y = self.view.bounds.origin.y - arrowOffset
        hostingVc.ftPresentationDelegate.source = self.view
        hostingVc.ftPresentationDelegate.sourceRect = rect
        hostingVc.ftPresentationDelegate.permittedArrowDirections = [UIPopoverArrowDirection.left, UIPopoverArrowDirection.right]
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
        if let parent = self.parent as? FTToolTypeShortcutContainerController {
            self.removeSizeEditViewIfNeeded()
            let hostingVc = FTPenSizeEditController(viewModel: viewModel, editPosition: position)
            hostingVc.view.backgroundColor = .white
            if parent.view.frame.size.width > minScreenWidthForPopover {
                parent.showSizeEditView(position: position, viewModel: viewModel)
            } else {
                let contentSize = FTPenSizeEditController.editViewSize
                self.ftPresentPopover(vcToPresent: hostingVc, contentSize: CGSize(width: contentSize.width, height: contentSize.height + 50.0))
            }
        }
    }

    func removeSizeEditViewIfNeeded() {
        if let parent = self.parent as? FTToolTypeShortcutContainerController {
            parent.removeSizeEditViewIfNeeded()
        }
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
        let rect = CGRect(x: self.view.bounds.origin.x, y: self.view.bounds.origin.y - arrowOffset, width: self.view.bounds.width, height: self.view.bounds.height)
        if let parent = self.parent as? FTToolTypeShortcutContainerController {
            let controller = FTShapesRackViewController.showPopOver(presentingController: parent, sourceView: self.view as Any, sourceRect: rect, arrowDirections: [.left, .right]) as? FTShapesRackViewController
            controller?.shapeEditDelegate = self
        }
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
