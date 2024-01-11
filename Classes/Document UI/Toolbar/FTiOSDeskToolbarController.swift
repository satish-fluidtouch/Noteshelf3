//
//  FTiOSDeskToolbarController.swift
//  Noteshelf
//
//  Created by Amar on 24/4/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

protocol FTDeskPanelActionDelegate: AnyObject {
    func didTapLeftPanelTool(_ buttonType: FTDeskLeftPanelTool, source:UIView)
    func didTapCenterPanelTool(_ buttonType: FTDeskCenterPanelTool, source:UIView)
    func didTapRightPanelTool(_ buttonType: FTDeskRightPanelTool, source:UIView, mode: FTScreenMode)
}

@objc protocol FTDeskToolbarDelegate: NSObjectProtocol {
    func currentDeskMode() -> RKDeskMode
    func lastSelectedPenMode() -> RKDeskMode
    func shapesToolEnabled() -> Bool
    func zoomModeEnabled() -> Bool

    @objc optional func canUndo() -> Bool
    @objc optional func undo()
    @objc optional func canRedo() -> Bool
    @objc optional func redo()
    @objc optional func notebookTitle() -> NSString
}

@objcMembers class FTiOSDeskToolbarController: UIViewController {
    @IBOutlet private weak var contentView: UIView?
    @IBOutlet private weak var contentTopConstraint: NSLayoutConstraint?
    @IBOutlet private weak var contentTopConstraintiPhone: NSLayoutConstraint?

    //Left Panel
    @IBOutlet private weak var leftPanelBlurView: FTToolbarVisualEffectView?
    @IBOutlet private weak var leftPanel: UIStackView?
    @IBOutlet weak var backButton: UIButton?
    @IBOutlet weak var finderButton: FTFinderButton?
    @IBOutlet weak var undoButton : UIButton?
    @IBOutlet weak var redoButton: UIButton?

    //Center Panel
    @IBOutlet private weak var centerPanelContainer: UIView?
    @IBOutlet private weak var centerPanelTopConstraint: NSLayoutConstraint?
    @IBOutlet private weak var centerPanelContainerWidthConstraint: NSLayoutConstraint?

    //Right Panel
    @IBOutlet private weak var rightPanelBlurView: FTToolbarVisualEffectView?
    @IBOutlet private weak var rightPanel: UIStackView?
    @IBOutlet weak var addButton: UIButton?
    @IBOutlet weak var shareButton: UIButton?
    @IBOutlet weak var fullScreenModeButton: UIButton!
    @IBOutlet weak var moreButton: UIButton?
    @IBOutlet weak var dividerLine: UIView?

    private var currentSize = CGSize.zero
    private var centerPanelVc: FTToolbarCenterPanelController?

    weak var delegate: FTDeskToolbarDelegate?
    weak var actionDelegate: FTDeskPanelActionDelegate?

    private(set) var screenMode = FTScreenMode.none {
        didSet {
            self.updatePanels()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
#if targetEnvironment(macCatalyst)
        self.view.isHidden = true
        self.contentTopConstraint?.constant = 0.0
#else
        self.handleObservers()
#endif
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let currentFrameSize = self.view.frame.size
        if(currentFrameSize.width != self.currentSize.width) {
            self.currentSize = currentFrameSize
            self.updateScreenModeIfNeeded(self.screenMode)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    class func viewController(_ delegate : FTDeskToolbarDelegate) -> FTiOSDeskToolbarController {
        let viewController = FTiOSDeskToolbarController.init(nibName: "FTiOSDeskToolbarController", bundle : nil)
        viewController.delegate = delegate
        return viewController
    }

    func updateDeskToolbarDelegate(_ delegate:FTDeskToolbarDelegate, actionDelegate: FTDeskPanelActionDelegate) {
        self.delegate = delegate
        self.actionDelegate = actionDelegate
        self.centerPanelVc?.updateActionDelegate(self)
    }

    func visualEffectView(for type: FTDeskPanel) -> FTToolbarVisualEffectView? {
        let view: FTToolbarVisualEffectView?
        if type == .left {
            view = self.leftPanelBlurView
        } else if type == .right {
            view = self.rightPanelBlurView
        } else {
            view = self.centerPanelVc?.centerPanelVisualEffectBlurView()
        }
        return view
    }

    private func handleObservers() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: FTValidateToolBarNotificationName), object: nil, queue: .main) { [weak self] notification in
            guard let strongSelf = self else {
                return
            }
            if strongSelf.view.window == notification.object as? UIWindow {
                strongSelf.validateUndoButton()
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: FTToggleToolbarModeNotificationName), object: nil, queue: .main) { [weak self] notification in
            guard let strongSelf = self else {
                return
            }
            if strongSelf.screenMode == .focus {
                strongSelf.focusViewTapped()
            } else {
                strongSelf.updateScreenModeIfNeeded(.focus)
                strongSelf.actionDelegate?.didTapRightPanelTool(.focus, source: strongSelf.fullScreenModeButton, mode: .focus)
            }
        }
        
        NotificationCenter.default.addObserver(forName: .validationFinderButtonNotification, object: nil, queue: .main) { [weak self] notification in
            guard let strongSelf = self else {
                return
            }
            if strongSelf.view.window == notification.object as? UIWindow {
                strongSelf.validateFinderButton()
            }
        }
    }

    private func updatePanels() {
        if self.screenMode == .shortCompact {
            self.centerPanelContainerWidthConstraint?.constant = self.view.frame.width
            self.centerPanelTopConstraint?.constant = 48.5
            self.shareButton?.isHidden = true
        } else if self.screenMode == .normal {
            self.centerPanelContainerWidthConstraint?.constant = 600.0
            self.centerPanelTopConstraint?.constant = 0.0
        }

        if let parent = self.parent as? FTDocumentRenderViewController {
            parent.updateScreenModeIfNeeded(self.screenMode)
        }

        if self.screenMode != .focus {
            self.view.layoutIfNeeded()
            self.centerPanelVc?.updateScreenMode(self.screenMode)
        }
    }

    private func updateScreenModeIfNeeded(_ mode: FTScreenMode) {
        if mode == .focus {
            if self.screenMode != .focus {
                self.screenMode = .focus
                self.configureNormalModeView(toAnimate: true)
            } else {
                self.configureNormalModeView(toAnimate: false)
            }
        } else {
            if UIDevice.current.isIphone() || self.view.frame.width < FTToolbarConfig.compactModeThreshold {
                self.screenMode = .shortCompact
            } else if self.screenMode != .normal {
                self.screenMode = .normal
            } else {
                self.centerPanelVc?.updateCenterPanel()
            }
        }
    }

    //MARK:- Undo/Redo Handler
    private func canUndo() -> Bool {
        var _canUndo = false
        if(self.delegate?.responds(to: #selector(FTDeskToolbarDelegate.canUndo)) != nil) {
            _canUndo = self.delegate!.canUndo!()
        }
        return _canUndo
    }
    
    private func canRedo() -> Bool {
        var _canRedo = false
        if(self.delegate?.responds(to: #selector(FTDeskToolbarDelegate.canRedo)) != nil) {
            _canRedo = self.delegate!.canRedo!()
        }
        return _canRedo
    }
    
    private func validateUndoButton() {
        self.undoButton?.isEnabled = false
        if self.redoButton?.isHidden ?? false {
            if self.canUndo() || self.canRedo() {
                self.undoButton?.isEnabled = true
            }
        } else {
            if(self.canUndo()) {
                self.undoButton?.isEnabled = true
            }
            if self.canRedo() {
                self.redoButton?.isEnabled = true
            }
        }
        self.redoButton?.isHidden = !self.canRedo()
    }
    
    private func validateFinderButton() {
        if let splitViewController = self.noteBookSplitViewController() {
            if splitViewController.isFinderVisible() {
                self.finderButton?.showFinderBg()
            } else {
                self.finderButton?.hideFinderBg()
            }
        }
    }
    
    var addNavButton: UIButton? {
        return self.addButton
    }
    
    var lassoNavButton: UIButton? {
        return nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "FTToolbarCenterPanelController", let controller = segue.destination as? FTToolbarCenterPanelController {
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            self.centerPanelVc = controller
            controller.delegate = self
        }
    }

    func getCenterPanelSourceView(for type: FTDeskCenterPanelTool) -> UIView? {
        var reqview = self.centerPanelContainer
        if let source = self.centerPanelVc?.getSourceView(for: type) {
            reqview = source
        }
        return reqview
    }

    private func performUndoIfNeeded() {
        if(self.canUndo()) {
            if(self.delegate?.responds(to: #selector(FTDeskToolbarDelegate.undo)) != nil) {
                self.delegate?.undo?()
            }
        }
    }

    private func performRedoIfNeeded() {
        if (self.canRedo()) {
            if (self.delegate?.responds(to: #selector(FTDeskToolbarDelegate.redo)) != nil) {
                self.delegate?.redo?()
            }
        }
    }
}

private extension FTiOSDeskToolbarController {
    //MARK:- Actions -
    @IBAction private func leftPanelButtonTapped(_ sender : UIButton) {
        if(sender == self.undoButton) {
            self.performUndoIfNeeded()
        } else if (sender == self.redoButton) {
            self.performRedoIfNeeded()
        } else {
            if let button = FTDeskLeftPanelTool.init(rawValue: sender.tag) {
                self.actionDelegate?.didTapLeftPanelTool(button, source: sender)
            }
        }
    }

    @IBAction private func rightPanelButtonTapped(_ sender: UIButton) {
        if sender == self.fullScreenModeButton {
            self.updateScreenModeIfNeeded(.focus)
            if let button = FTDeskRightPanelTool(rawValue: sender.tag) {
                self.actionDelegate?.didTapRightPanelTool(button, source: sender, mode: .focus)
            }
        } else {
            if let button = FTDeskRightPanelTool.init(rawValue: sender.tag) {
                self.actionDelegate?.didTapRightPanelTool(button, source: sender, mode: .normal)
            }
        }
    }
}

// Short Focus Mode Actions, Helper functions
extension FTiOSDeskToolbarController {
    private func configureNormalModeView(toAnimate: Bool = true) {
        if let parent = self.parent as? FTDocumentRenderViewController {
            if let focusModeView = parent.view.subviews.first(where: { $0 is FTFocusModeView }) {
                focusModeView.removeFromSuperview()
            }

            let focusView = FTFocusModeView()
            focusView.styleView()
            let focusViewOrigin = CGPoint(x: parent.view.frame.width + focusView.size.width, y: focusView.topOffset)
            focusView.frame.origin = focusViewOrigin

            let focusBtn = UIButton(type: .system)
            focusBtn.tintColor = .label
            focusBtn.addFullConstraints(focusView.contentView) // Focus view is UIVisualeffectview type, can't be added directly to any.
            focusBtn.setImage(UIImage(named: "desk_tool_expand"), for: .normal)
            focusBtn.addTarget(self, action: #selector(focusViewTapped), for: .touchUpInside)

            UIView.animate(withDuration: toAnimate ? 0.3 : 0.0) {
                parent.view.addSubview(focusView)
                parent.view.bringSubviewToFront(focusView)
                focusView.frame.origin.x -= ((2 * focusView.size.width) + 8.0)
            }
        }
    }

    @objc private func focusViewTapped() {
        if let parent = self.parent as? FTDocumentRenderViewController {
            if let focusModeView = parent.view.subviews.first(where: { $0 is FTFocusModeView }) {
                self.updateScreenModeIfNeeded(.normal)
                UIView.animate(withDuration: 0.3) {
                    self.actionDelegate?.didTapRightPanelTool(FTDeskRightPanelTool.focus, source: focusModeView, mode: .normal)
                    focusModeView.removeFromSuperview()
                }
            }
        }
    }
}

extension FTiOSDeskToolbarController: FTToolbarCenterPanelDelegate {
    func didTapCenterPanelButton(type: FTDeskCenterPanelTool, sender: UIView) {
        self.actionDelegate?.didTapCenterPanelTool(type, source: sender)
    }

    func isZoomModeEnabled() -> Bool {
        if let isEnabled = self.delegate?.zoomModeEnabled() {
            return isEnabled
        }
        return false
    }

    func currentDeskMode() -> RKDeskMode? {
        return self.delegate?.currentDeskMode()
    }

    func maxCenterPanelItemsToShow() -> Int {
        let itemCount: Int
        if self.screenMode == .shortCompact {
            let arrowsWidth = 2 * FTToolbarConfig.CenterPanel.NavButtonWidth.compact
            let maxAvailableSpace = self.view.frame.width - arrowsWidth
            itemCount = Int(maxAvailableSpace/48.0)
        } else {
            let leftPanelWidth: CGFloat = self.leftPanel?.frame.width ?? 0.0
            let rightPanelWidth: CGFloat = self.rightPanel?.frame.width ?? 0.0
            let minSpaceBtwPanels: CGFloat = 2 * 70.0 // Including arrows
            let margin: CGFloat = 2 * 8.0

            let maxAvailableSpace = self.view.frame.width - leftPanelWidth - rightPanelWidth - minSpaceBtwPanels - margin
            let countMax = Int(maxAvailableSpace/FTToolbarConfig.CenterPanel.DeskToolSize.regular.height)
            itemCount = countMax > 9 ? 9 : countMax
        }
        return itemCount
    }
}

final class FTFinderButton: FTBaseButton {
    override func awakeFromNib() {
        self.removeFinderBg()
        self.addFinderBg()
        hideFinderBg()
    }

    func hideFinderBg() {
        let bgBtn = self.subviews.first { $0 is FTToolBgButton }
        bgBtn?.isHidden = true
    }

    func showFinderBg() {
        let bgBtn = self.subviews.first { $0 is FTToolBgButton }
        bgBtn?.isHidden = false
    }

    private func addFinderBg() {
        let finderBgBtn = FTToolBgButton()
        finderBgBtn.layer.zPosition = -1
        finderBgBtn.isUserInteractionEnabled = false
        finderBgBtn.addFullConstraints(self, top: 6.0, bottom: 6.0, left: 2.0, right: 2.0)
        finderBgBtn.layoutIfNeeded()
        finderBgBtn.backgroundColor = .appColor(.white100)
        finderBgBtn.addRequiredShadow()
        self.sendSubviewToBack(finderBgBtn)
        self.hideFinderBg()
    }

    private func removeFinderBg() {
        let subviewsToRemove = self.subviews.filter { $0 is FTToolBgButton }
        subviewsToRemove.forEach { $0.removeFromSuperview() }
    }
}
