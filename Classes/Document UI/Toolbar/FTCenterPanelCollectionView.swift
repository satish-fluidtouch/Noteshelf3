//
//  FTCenterPanelCollectionView.swift
//  Noteshelf3
//
//  Created by Narayana on 29/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import FTCommon

protocol FTCenterPanelCollectionViewDelegate: FTToolbarCenterPanelDelegate {
    func getScreenMode() -> FTScreenMode
}

enum FTCenterPanelMode {
    case toolbar
    case circular
}

class FTCenterPanelCollectionView: UICollectionView {
    weak var centerPanelDelegate: FTCenterPanelCollectionViewDelegate?
    var dataSourceItems: [FTDeskCenterPanelTool] = []
   
    var mode: FTCenterPanelMode = .toolbar
    
    private var screenMode: FTScreenMode {
        return self.centerPanelDelegate?.getScreenMode() ?? .normal
    }
    
     var deskToolWidth: CGFloat {
        var reqWidth = FTToolbarConfig.CenterPanel.DeskToolSize.regular.width
        if self.screenMode == .shortCompact {
            reqWidth = FTToolbarConfig.CenterPanel.DeskToolSize.compact.width
        }
        return reqWidth
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.dataSource = self
        self.delegate = self
    }

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
    }
}

extension FTCenterPanelCollectionView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSourceItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let btnType = self.dataSourceItems[indexPath.row]
        let cell: UICollectionViewCell

        if btnType.toolMode == .shortcut {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTDeskShortcutCell", for: indexPath) as UICollectionViewCell
            var isSelected = false
            if let isEnabled = self.centerPanelDelegate?.isZoomModeEnabled(), btnType == .zoomBox {
                isSelected = isEnabled
            }
            (cell as? FTDeskShortcutCell)?.configureCell(type: btnType, isSelected: isSelected, mode: self.mode)

            // Selection handle closure
            (cell as? FTDeskShortcutCell)?.deskShortcutTapHandler = {[weak self, weak cell] in
                guard let self = self else { return }
                if let _cell = cell as? FTDeskShortcutCell {
                    _cell.isShortcutSelected = true;
                    self.centerPanelDelegate?.didTapCenterPanelButton(type: btnType, sender: _cell);
                    track(EventName.toolbar_tool_tap, params: [EventParameterKey.tool: btnType.localizedEnglish(), EventParameterKey.slot: indexPath.row + 1])
                }
            }
        } else {
              cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTDeskToolCell", for: indexPath) as UICollectionViewCell
            if let mode = self.centerPanelDelegate?.currentDeskMode() {
                let selected = FTDeskModeHelper.isToSelectDeskTool(mode: mode, toolType: btnType)
                (cell as? FTDeskToolCell)?.configureCell(type: btnType, isSelected: selected, mode: self.mode)
                (cell as? FTDeskToolCell)?.delegate = self

                // Selection handle closure
                (cell as? FTDeskToolCell)?.deskToolBtnTapHandler = {[weak self, weak cell] in
                    guard let self = self else { return }
                    self.resetSelection()
                    if let _cell = cell as? FTDeskToolCell {
                        _cell.isToolSelected = true
                        self.centerPanelDelegate?.didTapCenterPanelButton(type: btnType, sender: _cell)
                        track(EventName.toolbar_tool_tap, params: [EventParameterKey.tool: btnType.localizedEnglish(), EventParameterKey.slot: indexPath.row + 1])
                    }
                }
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    private func resetSelection() {
        for row in 0..<self.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: row, section: 0)
            if let cell = self.cellForItem(at: indexPath) as? FTDeskToolCell, cell.isToolSelected {
                cell.isToolSelected = false
            }
        }
    }
}

extension FTCenterPanelCollectionView: FTDeskToolCellDelegate {
    func currentDeskMode() -> RKDeskMode? {
        return self.centerPanelDelegate?.currentDeskMode()
    }

    func currentScreenMode() -> FTScreenMode {
        return self.centerPanelDelegate?.getScreenMode() ?? .normal
    }

    func getCurrentToolColor(toolType: FTDeskCenterPanelTool) -> UIColor {
        let userActivity = self.window?.windowScene?.userActivity
        let color = FTDeskModeHelper.getCurrentToolColor(toolType: toolType, userActivity: userActivity)
        return color
    }
}

