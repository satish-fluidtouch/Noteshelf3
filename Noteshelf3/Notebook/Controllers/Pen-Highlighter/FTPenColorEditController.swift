//
//  FTPenColorEditController.swift
//  Noteshelf3
//
//  Created by Narayana on 08/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon

extension NSNotification.Name  {
    static let PresetColorUpdate = NSNotification.Name(rawValue: "FTPresetColorUpdate")
}

enum FTColorToastType: String {
    case add
    case edit
    case delete
}

protocol FTFavoriteColorNotifier: AnyObject {
    func didSelectColorFromEditScreen(_ penset: FTPenSetProtocol)
    func saveFavoriteColorsIfNeeded()
}

extension FTFavoriteColorNotifier {
    func saveFavoriteColorsIfNeeded() {
        print("Required delegate ll implement it")
    }
}

protocol FTPenColorEditDelegate: AnyObject {
    func didAddPresetColor()
    func didDeletePresetColor()
    func didTapOnColorEyeDropper()
    func updateViewSizeIfNeeded(isPresetEdit: Bool)
    func didChangeCurrentPenset(_ penset: FTPenSetProtocol)
}

class FTPenColorEditController: UIHostingController<FTPenColorEditView>, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()

    static let presetViewSize = CGSize(width: 320.0, height: 293.0)
    static let gridViewSize = CGSize(width: 320.0, height: 402.0)

    private let viewModel: FTPenShortcutViewModel
    private weak var delegate: FTFavoriteColorNotifier?

    init(viewModel: FTPenShortcutViewModel, delegate: FTFavoriteColorNotifier? = nil) {
        self.viewModel = viewModel
        self.delegate = delegate
        let colorEditView = FTPenColorEditView(viewModel: viewModel)
        super.init(rootView: colorEditView)
        self.updateColorsFlowType(using: delegate)
        viewModel.createEditDelegate(editDelegate: self)
    }

    private func updateColorsFlowType(using delegate: FTFavoriteColorNotifier?) {
        guard let del = delegate else {
            let penType = self.viewModel.currentPenset.type
            self.viewModel.colorsFlow = FTColorsFlowType.penType(penType)
            return
        }
        switch del {
        case is FTPageViewController:
            self.viewModel.colorsFlow = .lasso
        case is FTShapeAnnotationController:
            self.viewModel.colorsFlow = .shape
        case is FTTextAnnotationViewController:
            self.viewModel.colorsFlow = .text
        default:
            let penType = self.viewModel.currentPenset.type
            self.viewModel.colorsFlow = FTColorsFlowType.penType(penType)
        }
    }

    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.appColor(.popoverBgColor)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.delegate?.saveFavoriteColorsIfNeeded()
        self.viewModel.updateCurrentColors()
    }
}

extension FTPenColorEditController: FTPenColorEditDelegate {
    func didTapOnColorEyeDropper() {
        let controller = self.presentingViewController
        if let presentingVc = controller {
            self.dismiss(animated: true) {
                if let shortcutVcDel = self.delegate as? FTToolTypeShortcutViewController {
                    FTColorEyeDropperPickerController.showEyeDropperOn(presentingVc,delegate: shortcutVcDel)
                } else if let pageDel = self.delegate as? FTPageViewController {
                    FTColorEyeDropperPickerController.showEyeDropperOn(presentingVc,delegate: pageDel)
                } else if let shapeAnnDel = self.delegate as? FTShapeAnnotationController {
                    FTColorEyeDropperPickerController.showEyeDropperOn(presentingVc,delegate: shapeAnnDel)
                } else if let textAnnDel = self.delegate as? FTTextAnnotationViewController {
                    FTColorEyeDropperPickerController.showEyeDropperOn(presentingVc,delegate: textAnnDel)
                }
            }
        }
    }
    
    func didChangeCurrentPenset(_ penset: FTPenSetProtocol) {
        self.delegate?.didSelectColorFromEditScreen(penset)
    }

    func updateViewSizeIfNeeded(isPresetEdit: Bool) {
        self.view.setNeedsLayout()
        self.view.layoutSubviews()
        self.view.layoutIfNeeded()
        if self.viewModel.colorEditSegment == .presets && !isPresetEdit {
            self.navigationController?.preferredContentSize = FTPenColorEditController.presetViewSize
        } else {
            self.navigationController?.preferredContentSize = FTPenColorEditController.gridViewSize
            if isPresetEdit {
                self.navigationController?.preferredContentSize.height -= 30.0
            }
        }
    }

    func didAddPresetColor() {
        NotificationCenter.default.post(name: .PresetColorUpdate, object: nil, userInfo: ["type": FTColorToastType.add.rawValue])
    }

    func didDeletePresetColor() {
        NotificationCenter.default.post(name: .PresetColorUpdate, object: nil, userInfo: ["type": FTColorToastType.delete.rawValue])
    }
}
