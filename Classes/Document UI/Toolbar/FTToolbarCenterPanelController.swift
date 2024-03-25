//
//  FTToolbarCenterPanelController.swift
//  Noteshelf3
//
//  Created by Narayana on 20/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

protocol FTToolbarCenterPanelDelegate: AnyObject {
    func isZoomModeEnabled() -> Bool
    func currentDeskMode() -> RKDeskMode?
    func maxCenterPanelItemsToShow() -> Int
    func didTapCenterPanelButton(type: FTDeskCenterPanelTool, sender: UIView)
}

class FTToolbarCenterPanelController: UIViewController {
    private weak var customToolbarObserver: NSObjectProtocol?;

    @IBOutlet private weak var containerView: FTToolbarVisualEffectView?
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var leftNavBtn: UIButton?
    @IBOutlet private weak var rightNavBtn: UIButton?
    @IBOutlet private weak var leftSpacer: UIView?
    @IBOutlet private weak var rightSpacer: UIView?

    @IBOutlet private weak var navBtnWidthConstraint: NSLayoutConstraint?
    @IBOutlet private weak var collectionViewWidthConstraint: NSLayoutConstraint?

    private var dataSourceItems: [FTDeskCenterPanelTool] = []
    private(set) var screenMode = FTScreenMode.normal

    weak var delegate: FTToolbarCenterPanelDelegate?

    private var deskToolWidth: CGFloat {
        var reqWidth = FTToolbarConfig.CenterPanel.DeskToolSize.regular.width
        if self.screenMode == .shortCompact {
            reqWidth = FTToolbarConfig.CenterPanel.DeskToolSize.compact.width
        }
        return reqWidth
    }

    private var navButtonWidth: CGFloat {
        var reqWidth = FTToolbarConfig.CenterPanel.NavButtonWidth.regular
        if self.screenMode == .shortCompact {
            reqWidth = FTToolbarConfig.CenterPanel.NavButtonWidth.compact
        }
        return reqWidth
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addObservers()
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.6
        self.view.addGestureRecognizer(longPressGesture)
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            FTCustomizeToolbarController.showCustomizeToolbarScreen(controller: self)
            // Track Event
            track(EventName.toolbar_longpress)
        }
    }

    deinit {
        if let observer = self.customToolbarObserver {
            NotificationCenter.default.removeObserver(observer);
        }
        NotificationCenter.default.removeObserver(self)
    }

    func centerPanelVisualEffectBlurView() -> FTToolbarVisualEffectView? {
        return self.containerView
    }

    func updateActionDelegate(_ del: FTToolbarCenterPanelDelegate) {
        self.delegate = del
    }

    func updateScreenMode(_ mode: FTScreenMode) {
        self.screenMode = mode
        self.updateCenterPanel()
    }

     func updateCenterPanel() {
        self.dataSourceItems = FTCurrentToolbarSection().displayTools
        guard let maxToShow = self.delegate?.maxCenterPanelItemsToShow() else {
            return
        }
        self.view.alpha = self.dataSourceItems.isEmpty ? 0.0 : 1.0
        self.navBtnWidthConstraint?.constant = navButtonWidth
        if self.screenMode == .shortCompact {
            self.updateSpacersIfNeeded(show: false)
            self.collectionViewWidthConstraint?.constant = self.view.frame.width - (2.0 * navButtonWidth)
        } else {
            var reqItemsCount = maxToShow
            if maxToShow > self.dataSourceItems.count {
                reqItemsCount = self.dataSourceItems.count
            }
            self.collectionViewWidthConstraint?.constant = CGFloat(reqItemsCount) * deskToolWidth
        }
        self.view.layoutIfNeeded()
        if self.dataSourceItems.count <= maxToShow {
            self.updateSpacersIfNeeded(show: true)
            self.updateNavButtons(show: false)
            self.collectionView.isScrollEnabled = false
        } else {
            self.updateSpacersIfNeeded(show: false)
            self.updateNavButtons(show: true)
            self.collectionView.isScrollEnabled = true
        }
        runInMainThread(0.1) {
            self.updateCurrentStatusOfNavButtons()
        }
    }
}

private extension FTToolbarCenterPanelController {
    private func updateSpacersIfNeeded(show: Bool) {
        if self.screenMode != .shortCompact {
            self.leftSpacer?.isHidden = !show
            self.rightSpacer?.isHidden = !show
        }
    }

    private func updateNavButtons(show: Bool) {
        self.leftNavBtn?.isHidden = !show
        self.rightNavBtn?.isHidden = !show
    }
    
    private func addObservers() {
        self.customToolbarObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: notifyToolbarCustomization)
                                               , object: nil, queue: nil) { [weak self] (_) in
            runInMainThread {
                guard let strongSelf = self else {
                    return
                }
                let currentSavedItems = FTCurrentToolbarSection().displayTools
                if strongSelf.dataSourceItems != currentSavedItems {
                    strongSelf.updateCenterPanel()
                    strongSelf.collectionView.collectionViewLayout.invalidateLayout()
                    strongSelf.collectionView.reloadData()
                }
            }
        }
    }

    @IBAction func leftBtnTapped(_ sender: Any) {
        if self.collectionView.contentOffset.x > 0.0 {
            self.disableNavButtons()
            let reqOffsetX = self.collectionView.contentOffset.x - self.deskToolWidth
            let yOffset = self.collectionView.contentOffset.y
            self.collectionView.setContentOffset(CGPoint(x: reqOffsetX, y: yOffset), animated: true)
            self.updateCurrentStatusOfNavButtons()
            FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.toolbar_left_arrow_tap)
        }
    }

    @IBAction func rightBtnTapped(_ sender: Any) {
        if self.collectionView.contentOffset.x < self.collectionView.contentSize.width - self.collectionView.frame.width {
            self.disableNavButtons()
            let reqOffsetX = self.collectionView.contentOffset.x + self.deskToolWidth
            let yOffset = self.collectionView.contentOffset.y
            self.collectionView.setContentOffset(CGPoint(x: reqOffsetX, y: yOffset), animated: true)
            self.updateCurrentStatusOfNavButtons()
            FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.toolbar_right_arrow_tap)
        }
    }

     func disableNavButtons() {
        self.leftNavBtn?.isEnabled = false
        self.rightNavBtn?.isEnabled = false
    }

     func updateCurrentStatusOfNavButtons() {
        var toEnableLeft: Bool = false
        var toEnableRight: Bool = false
        if(self.collectionView.contentOffset.x >= self.collectionView.contentSize.width - self.collectionView.frame.width) {
            toEnableRight = false
        } else {
            toEnableRight = true
        }
        if self.collectionView.contentOffset.x > 0.0 {
            toEnableLeft = true
        } else {
            toEnableLeft = false
        }
        self.leftNavBtn?.isEnabled = toEnableLeft
        self.rightNavBtn?.isEnabled = toEnableRight
    }
}

// For outside world
extension FTToolbarCenterPanelController {
    func getSourceView(for btnType: FTDeskCenterPanelTool) -> UIView {
        var reqView: UIView = self.view
        var indexPath = IndexPath(row: 0, section: 0)
        if let index = self.dataSourceItems.firstIndex(where: { type in
            type == btnType
        }) {
            indexPath.row = index
        }
        if let cell = self.collectionView.cellForItem(at: indexPath) {
            reqView = cell
        }
        return reqView
    }
}

extension FTToolbarCenterPanelController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSourceItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let btnType = self.dataSourceItems[indexPath.row]
        let cell: UICollectionViewCell

        if btnType.toolMode == .shortcut {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTDeskShortcutCell", for: indexPath) as UICollectionViewCell
            var isSelected = false
            if let isEnabled = self.delegate?.isZoomModeEnabled(), btnType == .zoomBox {
                isSelected = isEnabled
            }
            (cell as? FTDeskShortcutCell)?.configureCell(type: btnType, isSelected: isSelected)

            // Selection handle closure
            (cell as? FTDeskShortcutCell)?.deskShortcutTapHandler = {[weak self, weak cell] in
                guard let self = self else { return }
                if let _cell = cell as? FTDeskShortcutCell {
                    _cell.isShortcutSelected = true;
                    self.delegate?.didTapCenterPanelButton(type: btnType, sender: _cell);
                    track(EventName.toolbar_tool_tap, params: [EventParameterKey.tool: btnType.localizedEnglish(), EventParameterKey.slot: indexPath.row + 1])
                }
            }
        } else {
              cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTDeskToolCell", for: indexPath) as UICollectionViewCell
            if let mode = self.delegate?.currentDeskMode() {
                let selected = FTDeskModeHelper.isToSelectDeskTool(mode: mode, toolType: btnType)
                (cell as? FTDeskToolCell)?.configureCell(type: btnType, isSelected: selected)
                (cell as? FTDeskToolCell)?.delegate = self

                // Selection handle closure
                (cell as? FTDeskToolCell)?.deskToolBtnTapHandler = {[weak self, weak cell] in
                    guard let self = self else { return }
                    self.resetSelection()
                    if let _cell = cell as? FTDeskToolCell {
                        _cell.isToolSelected = true
                        self.delegate?.didTapCenterPanelButton(type: btnType, sender: _cell)
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
        for row in 0..<self.collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: row, section: 0)
            if let cell = collectionView.cellForItem(at: indexPath) as? FTDeskToolCell, cell.isToolSelected {
                cell.isToolSelected = false
            }
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.updateCurrentStatusOfNavButtons()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.updateCurrentStatusOfNavButtons()
        FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.toolbar_tools_swipe)

    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.updateCurrentStatusOfNavButtons()
            FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.toolbar_tools_swipe)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.disableNavButtons()
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let currentOffsetX = scrollView.contentOffset.x + (velocity.x * 300.0)
        var nearstOffsetX: CGFloat = 0.0
        if currentOffsetX <= 0.0 {

        } else if currentOffsetX >= scrollView.contentSize.width - scrollView.bounds.width {
            nearstOffsetX = scrollView.contentSize.width - scrollView.bounds.width
        } else {
            let cellWidth = Int(deskToolWidth)
            nearstOffsetX = CGFloat(self.roundUp(value: Int(currentOffsetX), divisor: cellWidth))
        }
        targetContentOffset.pointee.x = CGFloat(nearstOffsetX)
    }

    private func roundUp(value: Int, divisor: Int) -> Int {
        let modulo = value % divisor
        var multiplier = value / divisor
        if modulo > divisor/2 {
            multiplier += 1
        }
        return divisor * multiplier
    }
}

extension FTToolbarCenterPanelController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.screenMode == .shortCompact {
            return FTToolbarConfig.CenterPanel.DeskToolSize.compact
        }
        return FTToolbarConfig.CenterPanel.DeskToolSize.regular
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        var edgeSet: UIEdgeInsets = .zero
        if self.screenMode == .shortCompact {
            guard var reqToShow = self.delegate?.maxCenterPanelItemsToShow() else {
                return edgeSet
            }
            if reqToShow > self.dataSourceItems.count {
                reqToShow = self.dataSourceItems.count
            }
            let avaSpace = self.collectionView.frame.width - (CGFloat(reqToShow) * deskToolWidth)
            edgeSet = UIEdgeInsets(top: 0.0, left: avaSpace/2, bottom: 0.0, right: avaSpace/2.0)
        }
        return edgeSet
    }
}

extension FTToolbarCenterPanelController: FTDeskToolCellDelegate {
    func currentDeskMode() -> RKDeskMode? {
        return self.delegate?.currentDeskMode()
    }

    func currentScreenMode() -> FTScreenMode {
        return self.screenMode
    }

    func getCurrentToolColor(toolType: FTDeskCenterPanelTool) -> UIColor {
        let userActivity = self.view.window?.windowScene?.userActivity
        let color = FTDeskModeHelper.getCurrentToolColor(toolType: toolType, userActivity: userActivity)
        return color
    }
}
