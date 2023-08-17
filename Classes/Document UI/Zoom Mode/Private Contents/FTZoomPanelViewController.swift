//
//  FTZoomPanelViewController.swift
//  Noteshelf
//
//  Created by Amar on 13/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTZoomPanelActionType: Int {
    case pen,highlighter,eraser,shape,panLeft,panRight,panNewLine,settings,undo,redo,palmResize
}

protocol FTZoomPanelViewControllerDelegate: AnyObject {
    func zoomPanelViewController(_ viewController: FTZoomPanelViewController,
                                 didTapOnView: UIView,
                                 actionType: FTZoomPanelActionType)
    func zoomPanelViewControllerWillShowUndoOptions(_ viewController: FTZoomPanelViewController)

    func zoomPanelHandleResizePanGesture(_ gesture: UIPanGestureRecognizer)
}

protocol FTZoomPanelViewControllerDataSource: AnyObject {
    var canUndo: Bool {get}
    var canRedo: Bool {get}
    var isShapeEnabled: Bool {get}
    var currentDeskMode: RKDeskMode {get}
    var zoomPanelButtonPositionIsLeft: Bool {get}
    var isSettingsShown: Bool {get}
}

class FTZoomPanelViewController: UIViewController {
    @IBOutlet private weak var settingsView: UIStackView?
    @IBOutlet private weak var penContentStackView: UIStackView?
    @IBOutlet private weak var arrowsView: UIStackView?

    @IBOutlet private weak var penToolView: FTDeskToolView!
    @IBOutlet private weak var highlighterToolView: FTDeskToolView!
    @IBOutlet private weak var eraserToolView: FTDeskToolView!
    @IBOutlet private weak var shapeToolView: FTDeskToolView!
    @IBOutlet private weak var panLeftButton: UIButton?
    @IBOutlet private weak var panRightButton: UIButton?
    @IBOutlet private weak var panDownButton: UIButton?
    @IBOutlet private weak var settingsBtnView: UIView?
    @IBOutlet private weak var undoView: UIView!
    @IBOutlet private weak var redoView: UIView!
    @IBOutlet private weak var undoButton: UIButton?
    @IBOutlet private weak var redoButton: UIButton?

    @IBOutlet private weak var settingsLeadingConstraint: NSLayoutConstraint?
    @IBOutlet private weak var arrowsTrailingConstraint: NSLayoutConstraint?

    @IBOutlet private weak var panGestureRecognizer: UIPanGestureRecognizer?

    private var oldSize = CGSize.zero
    private var touchBeganPoint = CGPoint.zero
    private let penToolTag: Int = 1001
    private let highlighterToolTag: Int = 1002
    private let eraserToolTag: Int = 1003
    private let shapeToolTag: Int = 1004

    weak var delegate: FTZoomPanelViewControllerDelegate?
    weak var dataSource: FTZoomPanelViewControllerDataSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureCenterTools()
        self.configureActions()
        self.validateUI()
        self.addObservers()
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: FTValidateToolBarNotificationName), object: nil, queue: nil) { [weak self] (_) in
            self?.validateUI()
        }
    }

    private func configureCenterTools() {
        self.penToolView.toolType = .pen
        self.penToolView.isSelected = false

        self.highlighterToolView.toolType = .highlighter
        self.highlighterToolView.isSelected = false

        self.eraserToolView.toolType = .eraser
        self.eraserToolView.isSelected = false

        self.shapeToolView.toolType = .shapes
        self.shapeToolView.isSelected = false
    }

    private func configureActions() {
        self.penToolView.deskToolBtnTapHandler = {[weak self] in
            guard let self = self else { return }
            self.delegate?.zoomPanelViewController(self,
                                                   didTapOnView: self.penToolView,
                                                   actionType: .pen)
        }

        self.highlighterToolView.deskToolBtnTapHandler = {[weak self] in
            guard let self = self else { return }
            self.delegate?.zoomPanelViewController(self,
                                                   didTapOnView: self.highlighterToolView,
                                                   actionType: .highlighter)
        }

        self.eraserToolView.deskToolBtnTapHandler = {[weak self] in
            guard let self = self else { return }
            self.delegate?.zoomPanelViewController(self,
                                                   didTapOnView: self.eraserToolView,
                                                   actionType: .eraser)
        }

        self.shapeToolView.deskToolBtnTapHandler = {[weak self] in
            guard let self = self else { return }
            self.delegate?.zoomPanelViewController(self,
                                                   didTapOnView: self.shapeToolView,
                                                   actionType: .shape)
        }
    }

    func layoutForcibly() {
        self.oldSize = CGSize.zero
        self.view.setNeedsLayout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if(self.view.bounds.size != self.oldSize) {
            self.oldSize = self.view.bounds.size
            self.updateConstraints()
        }
    }
                
    func validateUI() {
        guard let datasource = self.dataSource else {
            return
        }
        self.undoButton?.isEnabled = false
        self.undoButton?.isEnabled = datasource.canUndo

        self.redoButton?.isHidden = true
        self.redoButton?.isHidden = !datasource.canRedo
        self.resetToolsSelection()

        let activity = self.view.window?.windowScene?.userActivity
        switch datasource.currentDeskMode {
        case .deskModePen:
            let pen = FTRackData(type: .pen, userActivity: activity).getCurrentPenSet()
            self.configure(for: .pen, with: UIColor(hexString: pen.color))

        case .deskModeMarker:
            let highlighter = FTRackData(type: .highlighter, userActivity: activity).getCurrentPenSet()
            self.configure(for: .highlighter, with: UIColor(hexString: highlighter.color))

        case .deskModeEraser:
            self.configure(for: .eraser)

        case .deskModeShape:
            let shape = FTRackData(type: .shape, userActivity: activity).getCurrentPenSet()
            self.configure(for: .shapes, with: UIColor(hexString: shape.color))

        default:
            break
        }
    }

    private func configure(for tool: FTDeskCenterPanelTool, with tintColor: UIColor = .clear) {
        switch tool {
        case .pen:
            self.penToolView.isSelected = true
            self.penToolView.applyTint(color: tintColor)

        case .highlighter:
            self.highlighterToolView.isSelected = true
            self.highlighterToolView.applyTint(color: tintColor)

        case .eraser:
            self.eraserToolView.isSelected = true

        case .shapes:
            self.shapeToolView.isSelected = true
            self.shapeToolView.applyTint(color: tintColor)

        default:
            break
        }
    }

    private func resetToolsSelection() {
        self.penToolView.isSelected = false
        self.highlighterToolView.isSelected = false
        self.eraserToolView.isSelected = false
        self.shapeToolView.isSelected = false

        self.penToolView.resetTint()
        self.highlighterToolView.resetTint()
        self.shapeToolView.resetTint()
    }
}

//MARK: - private -
private extension FTZoomPanelViewController {
    func updateConstraints() {
        guard let leftView = self.settingsView, let rightView = self.arrowsView else {
            return
        }
        let leftSubViewsOrder = [self.settingsBtnView, self.undoView, self.redoView]
        let rightOrderSubViews = [self.redoView, self.undoView, self.settingsBtnView]

        if self.dataSource?.zoomPanelButtonPositionIsLeft ?? false {
            for subView in leftView.subviews {
                leftView.removeArrangedSubview(subView)
                leftView.setNeedsLayout()
                leftView.layoutIfNeeded()
            }

            for leftOrderSubView in leftSubViewsOrder {
                if let btn = leftOrderSubView {
                    leftView.addArrangedSubview(btn)
                    leftView.setNeedsLayout()
                    leftView.layoutIfNeeded()
                }
            }
            self.settingsLeadingConstraint?.constant = 8.0
            self.arrowsTrailingConstraint?.constant = 8.0
        } else {
            for subView in leftView.subviews {
                leftView.removeArrangedSubview(subView)
                leftView.setNeedsLayout()
                leftView.layoutIfNeeded()
            }

            for rightOrderSubView in rightOrderSubViews {
                if let btn = rightOrderSubView {
                    leftView.addArrangedSubview(btn)
                    leftView.setNeedsLayout()
                    leftView.layoutIfNeeded()
                }
            }
            self.settingsLeadingConstraint?.constant = self.view.bounds.width - leftView.frame.width - 8.0
            self.arrowsTrailingConstraint?.constant = self.view.bounds.width - rightView.frame.width - 8.0
        }
        self.penContentStackView?.isHidden = !(self.view.bounds.width > 470)
    }
}

//MARK: - UIGestureRecognizerDelegate -
extension FTZoomPanelViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

//MARK: - Actions -
extension FTZoomPanelViewController {
    @IBAction private func didTapOnPanOptionsButton(_ sender:UIButton)
    {
        if sender == panLeftButton {
            self.delegate?.zoomPanelViewController(self,
                                                   didTapOnView: sender,
                                                   actionType: .panLeft)
        }
        else if sender == panRightButton {
            self.delegate?.zoomPanelViewController(self,
                                                   didTapOnView: sender,
                                                   actionType: .panRight)
        }
        else if sender == panDownButton {
            self.delegate?.zoomPanelViewController(self,
                                                   didTapOnView: sender,
                                                   actionType: .panNewLine)
        }
    }
    
    @IBAction private func didTapOnSettingsButton(_ sender:UIButton)
    {
        self.delegate?.zoomPanelViewController(self,
                                               didTapOnView: sender,
                                               actionType: .settings)
    }
    
    @IBAction private func didTapOnUndoRedoButton(_ sender: UIButton)
    {
        guard let _datasource = self.dataSource else {
            return
        }
        if _datasource.canUndo && sender == self.undoButton {
            self.delegate?.zoomPanelViewController(self,
                                                   didTapOnView: sender,
                                                   actionType: .undo)
        } else if _datasource.canRedo && sender == self.redoButton {
            self.delegate?.zoomPanelViewController(self,
                                                   didTapOnView: sender,
                                                   actionType: .redo)
        }
    }

    @objc private func didTapOnPalmRestButton(_ sender: UIButton) {
//        self.delegate?.zoomPanelViewController(self, didTapOnButton: sender, actionType: .palmResize)
        debugLog("didMoveOnPalmRestButton")
    }
    
    @IBAction private func panGestureDidPan(_ gesture: UIPanGestureRecognizer) {
        self.delegate?.zoomPanelHandleResizePanGesture(gesture)
    }
}
