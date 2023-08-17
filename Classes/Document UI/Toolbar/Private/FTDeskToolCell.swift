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
        self.handleObservers()
    }

    var isToolSelected: Bool = false {
        didSet {
            self.deskToolView?.isSelected = isToolSelected
            self.applyTintIfNeeded()
        }
    }

    func configureCell(type: FTDeskCenterPanelTool, isSelected: Bool) {
        self.toolType = type
        self.deskToolView?.toolType = type
        self.isToolSelected = isSelected
    }

    private func handleObservers() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: FTValidateToolBarNotificationName), object: nil, queue: .main) { [weak self] notification in
            guard let strongSelf = self else {
                return
            }
            if strongSelf.window == notification.object as? UIWindow, let type = strongSelf.toolType, let mode = strongSelf.delegate?.currentDeskMode() {
                if FTDeskModeHelper.isToSelectDeskTool(mode: mode, toolType: type) {
                    strongSelf.isToolSelected = true
                } else if type.toolMode != .shortcut {
                    strongSelf.isToolSelected = false
                }
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("FTPenTypeDisplayChange"), object: nil, queue: nil) { [weak self] notification in
            self?.applyTintIfNeeded()
        }
    }

    private func applyTintIfNeeded() {
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

    func configureCell(type: FTDeskCenterPanelTool, isSelected: Bool) {
        self.deskShortcutView?.toolType = type
        self.deskShortcutView?.isSelected = isSelected
    }

    var isShortcutSelected: Bool = false {
        didSet {
            self.deskShortcutView?.isSelected = isShortcutSelected
        }
    }
}
