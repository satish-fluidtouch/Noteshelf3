//
//  FTiOSDeskToolbarController.swift
//  Noteshelf
//
//  Created by Amar on 24/4/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

extension Notification.Name {
    static let leftPanelPopupDismiss = Notification.Name(rawValue: "leftPanelPopupDismiss")
}

protocol FTDeskPanelActionDelegate: AnyObject {
    func didTapLeftPanelTool(_ buttonType: FTDeskLeftPanelTool, source:UIView)
    func didTapCenterPanelTool(_ buttonType: FTDeskCenterPanelTool, source:UIView)
    func didTapRightPanelTool(_ buttonType: FTDeskRightPanelTool, source:UIView, mode: FTScreenMode)
}

@objc protocol FTDeskToolbarDelegate: NSObjectProtocol {
    func currentDeskMode() -> RKDeskMode
    func lastSelectedPenMode() -> RKDeskMode
    func shapesToolEnabled() -> Bool
    func isAudioRecordedViewPresented() -> Bool
    func getDeskToolBarHeight() -> CGFloat
    func status(for tool: FTDeskCenterPanelTool) -> NSNumber?

    @objc optional func canUndo() -> Bool
    @objc optional func undo()
    @objc optional func canRedo() -> Bool
    @objc optional func redo()
    @objc optional func notebookTitle() -> NSString
}

@objcMembers class FTiOSDeskToolbarController: UIViewController {
    @IBOutlet private weak var contentView: UIView?
    @IBOutlet private weak var contentTopConstraint: NSLayoutConstraint?
    
    private(set)var focusModeView: FTFocusModeView?;
    
    //Left Panel
    @IBOutlet private weak var leftPanelBlurView: FTToolbarVisualEffectView?
    @IBOutlet private weak var leftPanel: UIStackView?
    @IBOutlet weak var backButton: FTToolBarButton?
    @IBOutlet weak var finderButton: FTToolBarButton?
    @IBOutlet weak var undoButton : FTToolBarButton?
    @IBOutlet weak var redoButton: FTToolBarButton?
    
    //Center Panel
    @IBOutlet private weak var centerPanelContainer: UIView?
    @IBOutlet private weak var centerPanelTopConstraint: NSLayoutConstraint?
    @IBOutlet private weak var centerPanelContainerWidthConstraint: NSLayoutConstraint?
    
    //Right Panel
    @IBOutlet private weak var rightPanelBlurView: FTToolbarVisualEffectView?
    @IBOutlet private weak var rightPanel: UIStackView?
    @IBOutlet weak var addButton: FTToolBarButton?
    @IBOutlet weak var shareButton: UIButton?
    @IBOutlet weak var fullScreenModeButton: UIButton!
    @IBOutlet weak var moreButton: FTToolBarButton?
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
#endif
        self.handleObservers()
        self.popupDismissStatus()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let currentFrameSize = self.view.frame.size
        if(currentFrameSize.width != self.currentSize.width) {
            var space: CGFloat = 0.0
            if UIDevice.current.isPhone() {
                if let window = UIApplication.shared.keyWindow ?? self.view.window {
                    self.currentSize = currentFrameSize
                    space = window.safeAreaInsets.top
                }
            } else {
                self.currentSize = currentFrameSize
            }
            self.updateScreenModeIfNeeded(self.screenMode)
#if targetEnvironment(macCatalyst)
            self.contentTopConstraint?.constant = 0.0
#else
            self.contentTopConstraint?.constant = 14.0 + space
#endif
        }
    }
    
    deinit {
        if let observer = self.validateToolbarObserver {
            NotificationCenter.default.removeObserver(observer);
        }
        if let observer = self.validateFinderButtonObserver {
            NotificationCenter.default.removeObserver(observer);
        }
        if let observer = self.toggleToolbarObserver {
            NotificationCenter.default.removeObserver(observer);
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    class func viewController(_ delegate : FTDeskToolbarDelegate) -> FTiOSDeskToolbarController {
        let viewController = FTiOSDeskToolbarController.init(nibName: "FTiOSDeskToolbarController", bundle : nil)
        viewController.delegate = delegate
        return viewController
    }
    
    
    func updateToolStatus(for tool : FTDeskCenterPanelTool , status : Bool){
        self.centerPanelVc?.updateCellStatus(for: tool, status: status)
    }
    
    func rightPanelPopupDismissStatus(){
        moreButton?.hideBg()
        addButton?.hideBg()
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
        
        private weak var validateToolbarObserver: NSObjectProtocol?;
        private weak var toggleToolbarObserver: NSObjectProtocol?;
        private weak var validateFinderButtonObserver: NSObjectProtocol?;
        private func handleObservers() {
            self.validateToolbarObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: FTValidateToolBarNotificationName), object: nil, queue: .main) { [weak self] notification in
                guard let strongSelf = self else {
                    return
                }
                if strongSelf.view.window == notification.object as? UIWindow {
                    strongSelf.validateUndoButton()
                }
            }
            
            self.toggleToolbarObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: FTToggleToolbarModeNotificationName), object: nil, queue: .main) { [weak self] notification in
                guard let strongSelf = self else {
                    return
                }
                if strongSelf.screenMode == .focus {
                    strongSelf.focusViewTapped()
                } else {
                    strongSelf.updateScreenModeIfNeeded(.focus)
                    strongSelf.actionDelegate?.didTapRightPanelTool(.focus, source: strongSelf.fullScreenModeButton, mode: .focus)
                    FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.focusmode_gesture_toggle, params: ["toggle": "on"])
                }
            }
            
            self.validateFinderButtonObserver = NotificationCenter.default.addObserver(forName: .validationFinderButtonNotification, object: nil, queue: .main) { [weak self] notification in
                guard let strongSelf = self else {
                    return
                }
                if strongSelf.view.window == notification.object as? UIWindow {
                    strongSelf.validateFinderButton()
                }
            }
        }
        
        func didChangePageLayout() {
            if let parent = self.parent as? FTDocumentRenderViewController {
                parent.didChangePageLayout()
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
                if UIDevice().isIphone() || self.view.frame.width < FTToolbarConfig.compactModeThreshold {
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
                    self.finderButton?.showBg()
                } else {
                    self.finderButton?.hideBg()
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
                self.undoButton?.showBg()
                runInMainThread(0.1) {
                    self.undoButton?.hideBg()
                }
                self.performUndoIfNeeded()
                FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.toolbar_undo_tap)
            } else if (sender == self.redoButton) {
                self.redoButton?.showBg()
                runInMainThread(0.1) {
                    self.redoButton?.hideBg()
                }
                self.performRedoIfNeeded()
                FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.toolbar_redo_tap)
            } else {
                if let button = FTDeskLeftPanelTool(rawValue: sender.tag) {
                    if button == .back {
                        self.backButton?.showBg(isInstanse:true)
                        runInMainThread(0.1) {
                            self.actionDelegate?.didTapLeftPanelTool(button, source: sender)
                        }
                    }else {
                        self.actionDelegate?.didTapLeftPanelTool(button, source: sender)
                    }
                }
            }
        }
        
        @IBAction private func rightPanelButtonTapped(_ sender: UIButton) {
            if sender == self.fullScreenModeButton {
                self.updateScreenModeIfNeeded(.focus)
                FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.toolbar_focusmode_toggle, params: ["toggle": "on"])
                if let button = FTDeskRightPanelTool(rawValue: sender.tag) {
                    self.actionDelegate?.didTapRightPanelTool(button, source: sender, mode: .focus)
                }
            } else {
                if let button = FTDeskRightPanelTool.init(rawValue: sender.tag) {
                    self.actionDelegate?.didTapRightPanelTool(button, source: sender, mode: .normal)
                    if button == .add {
                        self.addButton?.showBg()
                    } else if button == .more {
                        self.moreButton?.showBg()
                    }
                }
                
            }
        }
        
        func addBgView(button: UIButton) {
            let view =  UIView()
            view.addFullConstraints(button,top:6.0,bottom: 6.0, left:2.0,right: 2.0)
            view.backgroundColor = UIColor.appColor(.accentBg)
            view.layer.cornerRadius = 7.0
            button.addSubview(view)
        }
    }
    
    // Short Focus Mode Actions, Helper functions
    extension FTiOSDeskToolbarController {
        private func configureNormalModeView(toAnimate: Bool = true) {
            if let parent = self.parent as? FTDocumentRenderViewController {
                if let focusModeView = self.focusModeView {
                    focusModeView.removeFromSuperview()
                }
                
                let focusView = FTFocusModeView()
                self.focusModeView = focusView
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
            if let focusModeView = self.focusModeView {
                self.updateScreenModeIfNeeded(.normal)
                FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.toolbar_focusmode_toggle, params: ["toggle": "off"])
                UIView.animate(withDuration: 0.3) {
                    self.actionDelegate?.didTapRightPanelTool(FTDeskRightPanelTool.focus, source: focusModeView, mode: .normal)
                    focusModeView.removeFromSuperview()
                }
            }
        }
    }
    
extension FTiOSDeskToolbarController: FTToolbarCenterPanelDelegate {
        func status(for tool: FTDeskCenterPanelTool) -> NSNumber? {
            return self.delegate?.status(for: tool)
        }
    
        func getHeightforToolBar() -> CGFloat {
            return self.delegate?.getDeskToolBarHeight() ?? 0.0
        }
        
        func isAudioRecordedViewPresented() -> Bool {
            return self.delegate?.isAudioRecordedViewPresented() ?? false
        }
        
        
        func didTapCenterPanelButton(type: FTDeskCenterPanelTool, sender: UIView) {
            self.actionDelegate?.didTapCenterPanelTool(type, source: sender)
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
    @IBDesignable
    final class FTToolBarButton: FTBaseButton {
        
        @IBInspectable var selectedBg : UIColor = UIColor.appColor(.white100)
        
        override func awakeFromNib() {
            self.removeFinderBg()
            self.addFinderBg()
            hideBg()
        }
        
        func hideBg() {
            let bgBtn = self.viewWithTag(1)
            bgBtn?.isHidden = true
        }
        
        func showBg(isInstanse : Bool = false) {
            let bgBtn = self.viewWithTag(1)
            bgBtn?.isHidden = false
        }
        
        private func addFinderBg() {
            let finderBgBtn = FTToolBgButton()
            finderBgBtn.tag = 1
            finderBgBtn.layer.zPosition = -1
            finderBgBtn.isUserInteractionEnabled = false
            finderBgBtn.addFullConstraints(self, top: 6.0, bottom: 6.0, left: 2.0, right: 2.0)
            finderBgBtn.layoutIfNeeded()
            finderBgBtn.backgroundColor = selectedBg
            finderBgBtn.addRequiredShadow()
            self.sendSubviewToBack(finderBgBtn)
            self.hideBg()
        }
        
        private func removeFinderBg() {
            let subviewsToRemove = self.subviews.filter { $0 is FTToolBgButton }
            subviewsToRemove.forEach { $0.removeFromSuperview() }
        }
        
        
    }
    
    extension FTiOSDeskToolbarController  {
        func popupDismissStatus(){
            NotificationCenter.default.addObserver(self, selector: #selector(self.leftPanelPopupDismissStatus(notification:)), name: .leftPanelPopupDismiss, object: nil)
        }
        
        @objc func leftPanelPopupDismissStatus(notification: Notification) {
            if let window = self.view.window,
               let sourceWindow = notification.object as? UIWindow,
               window == sourceWindow{
                backButton?.hideBg()
            }
        }
    }
    

