//
//  FTDeskToolCell.swift
//  Noteshelf3
//
//  Created by Narayana on 20/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTDeskToolCellDelegate: AnyObject {
    func currentDeskMode() -> RKDeskMode?
    func currentScreenMode() -> FTScreenMode
    func getCurrentToolColor(toolType: FTDeskCenterPanelTool) -> UIColor
}

class FTDeskToolCell: UICollectionViewCell {
    private weak var deskToolView: FTDeskToolView?

    var toolType: FTDeskCenterPanelTool!
    weak var delegate: FTDeskToolCellDelegate?
    var deskToolBtnTapHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        guard let toolView = self.contentView as? FTDeskToolView else {
            fatalError("Programmer error, revisit configuration")
        }
        self.deskToolView = toolView
        self.deskToolView?.deskToolBtnTapHandler = {[weak self] in
            guard let self = self else { return }
            self.deskToolBtnTapHandler?()
        }
    }

    var isToolSelected: Bool = false {
        didSet {
            self.deskToolView?.isSelected = isToolSelected
            self.applyTintIfNeeded(nil)
        }
    }

    func configureCell(type: FTDeskCenterPanelTool, isSelected: Bool, mode: FTCenterPanelMode) {
        self.deskToolView?.mode = mode
        self.toolType = type
        self.deskToolView?.toolType = type
        self.isToolSelected = isSelected
        self.handleObservers()
    }

    private func handleObservers() {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(validateToolbar), name: NSNotification.Name(rawValue: FTValidateToolBarNotificationName), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(applyTintIfNeeded), name: .penTypeDisplayChange, object: self.window?.windowScene)
    }

    @objc func validateToolbar(_ notification: Notification?) {
        if self.window == notification?.object as? UIWindow, let type = self.toolType, let mode = self.delegate?.currentDeskMode() {
            if FTDeskModeHelper.isToSelectDeskTool(mode: mode, toolType: type) {
                self.isToolSelected = true
            } else if type.toolMode != .shortcut {
                self.isToolSelected = false
            }
        }
    }

    @objc func applyTintIfNeeded(_ notification: Notification?) {
        if self.toolType.isColorEditTool() && isToolSelected {
            let tintColor = self.delegate?.getCurrentToolColor(toolType: self.toolType)
            self.deskToolView?.applyTint(color: tintColor ?? .clear)
        } else {
            self.deskToolView?.resetTint()
        }
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: FTValidateToolBarNotificationName),
                                                  object: nil)
    }

    deinit {
        self.removeObservers()
    }
}

class FTDeskShortcutCell: UICollectionViewCell {
    private weak var deskShortcutView: FTDeskShortcutView?
    var deskShortcutTapHandler: (() -> Void)?

    weak var delegate: FTDeskToolCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        guard let toolView = self.contentView as? FTDeskShortcutView else {
            fatalError("Programmer error, revisit configuration")
        }
        self.deskShortcutView = toolView
        self.deskShortcutView?.deskToolBtnTapHandler = {[weak self] in
            guard let self = self else { return }
            self.deskShortcutTapHandler?()
        }
    }

    func configureCell(type: FTDeskCenterPanelTool, isSelected: Bool, mode: FTCenterPanelMode) {
        self.deskShortcutView?.mode = mode
        self.deskShortcutView?.toolType = type
        self.deskShortcutView?.isSelected = isSelected
    }

    var isShortcutSelected: Bool = false {
        didSet {
            self.deskShortcutView?.isSelected = isShortcutSelected
        }
    }
}
