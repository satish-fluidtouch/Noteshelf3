//
//  FTDocumentRenderViewController.swift
//  Noteshelf
//
//  Created by Akshay on 25/10/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

typealias FTDocumentViewController = UIViewController & FTDocumentViewPresenter;
let textContainerTag: Int = 9001

@objc protocol FTDocumentViewPresenter : NSObjectProtocol {
    func configureDocumentView(_ info : FTDocumentOpenInfo);
    var relativePath : String? {get};
    var documentItemObject : FTDocumentItemWrapperObject {get};
    
    func didCompleteDocumentPresentation();
    func waitForTheDocmentToBeOpened();
    func canContinueToImportFiles() -> Bool;
    func showAlertAskingToEnterPwdToContinueOperation();
    func avoidAskingPwd();
    func removeBlurEffectForPassword(_ animated : Bool);
    func saveApplicationStateByClosingDocument(_ shouldClose : Bool,
                                               keepEditingOn : Bool,
                                               onCompletion :((Bool) -> Void)?);
    func startRecordingOnAudioNotebook();
    func didReceivePencilInteraction(_ action:FTApplePencilInteractionType);
    func insertNewPage(fromItem url:URL, onCompletion:((_ completed:Bool) -> Void)?);
    func addRecordingToPage(actionType: FTAudioActionType,
                            audio: FTAudioFileToImport,
                            onCompletion : ((Bool,NSError?) -> Void)?);
    func navigateToPage(index: Int)
}

protocol FTToolbarElements : NSObjectProtocol {
    func setToolbarEnabled(_ isEnabled:Bool)
    func toolbarSourceView(for type:FTDeskLeftPanelTool) -> UIView?
    func toolbarSourceView(for type:FTDeskCenterPanelTool) -> UIView?
    func toolbarSourceView(for type:FTDeskRightPanelTool) -> UIView?
    func toolbarHorizontalSizeClass() -> UIUserInterfaceSizeClass
    func isZoomHidden() -> Bool
    func isLassoHidden() -> Bool
    func isInFocusMode() -> Bool
}

@objcMembers class FTDocumentOpenInfo : NSObject
{
    private(set) var document: FTDocumentProtocol;
    private(set) var shelfItem : FTShelfItemProtocol;
    private(set) var currentPageIndex : Int = -1;
    var documentSearchResults : FTDocumentSearchResults?;
    var openAnimationInfo: FTOpenAnimationInfo?
    var documentOpenToken: FTDocumentOpenToken = FTDocumentOpenToken();
    
    required init(document inDocument : FTDocumentProtocol,
                  shelfItem inShelfItem: FTShelfItemProtocol,
                  index : Int = -1) {
        document = inDocument;
        shelfItem = inShelfItem;
        currentPageIndex = index;
        super.init()
    }
}

@objcMembers class FTOpenAnimationInfo : NSObject{
    var imageFrame: CGRect = CGRect.zero
    var shelfImage: UIImage?
    var animate: Bool = false
}

class FTDocumentRenderViewController: UIViewController {
    @IBOutlet private weak var contentHolderView:UIView?
    @IBOutlet private weak var toolBarView: FTToolbarView?

    @IBOutlet private weak var toolbarHeightConstraint: NSLayoutConstraint?
    @IBOutlet private weak var toolbarTopConstraint: NSLayoutConstraint?

    private var deskToolbarController: FTiOSDeskToolbarController?
    private var textToolbarController: FTTextToolBarViewController?
    private weak var delegate: FTOpenCloseDocumentProtocol?
    private var documentDidEnlargeForReadOnlyMode: Bool = false

    private weak var deskBarDelegate: FTDeskToolbarDelegate?
    private weak var deskPanelActionDelegate: FTDeskPanelActionDelegate?

    var documentViewController: FTPDFRenderViewController!
    private weak var loadingIndicator: FTLoadingIndicatorViewController?
    private var showRenderingIndicator = false

    private var isReady = FTDeveloperOption.bookScaleAnim {
        didSet {
            if(isReady != oldValue) {
                refreshStatusBarAppearnce();
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addToolbar()
        self.navigationController?.navigationBar.isHidden = true
        self.showRenderingIndicator = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        if(isReady) {
            refreshStatusBarAppearnce();
        }
        if showRenderingIndicator {
            self.showRenderingIndicator = false
            loadingIndicator = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("Loading", comment: "Loading..."), andDelay: 0.5);
        }
    }
    
    private func updateUIWithMode(_ mode: FTScreenMode) {
        var options = UIView.AnimationOptions.curveEaseOut
        if mode == .focus {
            options = .curveEaseIn
        }
        UIView.animate(withDuration: 0.3, delay: 0.0, options: options, animations: {
            if mode == .focus {
                self.toolbarTopConstraint?.constant = -200.0
            } else {
                self.toolbarTopConstraint?.constant = 0.0
            }
            self.view.layoutIfNeeded()
        })
    }

    func updateScreenModeIfNeeded(_ mode: FTScreenMode) {
        self.updateUIWithMode(mode)
        self.toolBarView?.screenMode = mode
        if mode == .shortCompact {
            var extraHeight: CGFloat = 0.0
            if UIDevice.current.isPhone() {
                if let window = UIApplication.shared.keyWindow {
                    let topSafeAreaInset = window.safeAreaInsets.top
                    if topSafeAreaInset > 0 {
                        extraHeight = topSafeAreaInset
                    }
                }
            }
            self.toolbarHeightConstraint?.constant = FTToolbarConfig.Height.compact + extraHeight
        } else if mode == .normal {
#if targetEnvironment(macCatalyst)
            self.toolbarHeightConstraint?.constant = 0.0
#else
            self.toolbarHeightConstraint?.constant = FTToolbarConfig.Height.regular
#endif
        }
        self.toolBarView?.layoutIfNeeded()
    }

    func deskToolBarHeight() -> CGFloat {
        return toolBarView?.frame.height ?? 0
    }

    func currentToolBarState() -> FTScreenMode {
        return deskToolbarController?.screenMode ?? .normal
    }

    /// Required Presentation method
    class func viewController(info : FTDocumentOpenInfo, delegate: FTOpenCloseDocumentProtocol?) -> FTDocumentRenderViewController {
        let storyboard = UIStoryboard(name: "FTDocumentView", bundle: nil)
        guard let controller = storyboard.instantiateInitialViewController() as? FTDocumentRenderViewController else {
            fatalError("Entry viewcontroller should be of type FTDocumentRenderViewController");
        }
        controller.delegate = delegate
        return controller
    }

    override var prefersStatusBarHidden: Bool {
        guard isReady else {
            return super.prefersStatusBarHidden;
        }
        var toHide: Bool = true
        if UIDevice.current.isPhone() {
            toHide = false
        }
        return toHide
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return self.prefersStatusBarHidden;
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if nil != self.view.window {
            documentViewController.didMove(toParent: self)
        }
    }

    func configureDocumentView(_ info : FTDocumentOpenInfo) {
        guard let _contentView = contentHolderView else {
            return;
        }
        documentViewController = FTPDFRenderViewController.init(documentInfo:info);
        documentViewController.shelfItemManagedObject = FTDocumentItemWrapperObject(documentItem:info.shelfItem)
        documentViewController.openCloseDocumentDelegate = self
        documentViewController.textToolbarDelegate = self
        self.addChild(documentViewController)
        documentViewController.view.frame = _contentView.bounds;
        _contentView.addSubview(documentViewController.view);
        documentViewController.view.addEqualConstraintsToView(toView: _contentView);
        if nil != self.view.window {
            documentViewController?.view.layoutIfNeeded();
            documentViewController.didMove(toParent: self);
        }
        self.deskBarDelegate = documentViewController
        self.deskPanelActionDelegate = documentViewController
        self.deskToolbarController?.updateDeskToolbarDelegate(self, actionDelegate: self)
        (documentViewController.pdfDocument as? FTRecognitionHelper)?.recognitionHelper?.startPendingRecognition()
        if FTVisionNotebookRecognitionHelper.supportsImageToTextRecognition() {
            (documentViewController.pdfDocument as? FTRecognitionHelper)?.visionRecognitionHelper?.startImageTextRecognition()
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
#if DEBUG
        debugPrint("deinit \(self.classForCoder)");
#endif
    }
}

private extension FTDocumentRenderViewController {
    func addToolbar() {
        if let toolbarVc = self.toolBarView?.addToolbar(), let toolBarView = self.toolBarView {
            addChild(toolbarVc)
            if let leftController = documentViewController {
                toolbarVc.delegate = leftController
            }
            self.view.bringSubviewToFront(toolBarView)
            self.deskToolbarController = toolbarVc
        }
    }
}

extension FTDocumentRenderViewController: FTToolbarElements {
    //MARK: - Enable or Disable Toolbar for some synchronous internal actions
    func setToolbarEnabled(_ isEnabled:Bool) {
        self.toolBarView?.isUserInteractionEnabled = isEnabled
        if isEnabled {
            showRenderingIndicator = false
            self.loadingIndicator?.hide()
        }
    }

    //MARK: - Child Controllers Helper Methods
    func toolbarSourceView(for type:FTDeskLeftPanelTool) -> UIView? {
        guard let deskToolbar = deskToolbarController else { return nil }
        var source: UIView?

        switch type {
        case .back:
            source = deskToolbar.backButton
        case .finder:
            source = deskToolbar.finderButton
        case .undo:
            source = deskToolbar.undoButton
        case .redo:
            source = deskToolbar.redoButton
        }
        return source
    }

    func toolbarSourceView(for type:FTDeskRightPanelTool) -> UIView? {
        guard let deskToolbar = deskToolbarController else { return nil }
        var source: UIView?

        switch type {
        case .add:
            source = deskToolbar.addButton
        case .share:
            source = deskToolbar.shareButton
        case .more:
            source = deskToolbar.moreButton
        case .focus:
            source = deskToolbar.fullScreenModeButton
        }
        return source
    }

    func toolbarSourceView(for type:FTDeskCenterPanelTool) -> UIView? {
        guard let deskToolbar = deskToolbarController else { return nil }
        let source = deskToolbar.getCenterPanelSourceView(for: type)
        return source
    }

    func toolbarHorizontalSizeClass() -> UIUserInterfaceSizeClass {
        return deskToolbarController?.traitCollection.horizontalSizeClass ?? .regular
    }
    
    func isZoomHidden() -> Bool {
        return true
    }
    
    func isLassoHidden() -> Bool {
        return deskToolbarController?.lassoNavButton?.isHidden ?? true
    }

    func isInFocusMode() -> Bool {
        var isFocusMode = false
        if deskToolbarController?.screenMode == .focus {
            isFocusMode = true
        }
        return isFocusMode
    }
 }


//MARK:- fileprivate member Variable Access methods
extension FTDocumentRenderViewController: FTDocumentViewPresenter {
    func navigateToPage(index: Int) {
        self.documentViewController.navigateToPage(index: index)
    }
    
    func didCompleteDocumentPresentation() {
        isReady = true;
        self.documentViewController.didCompleteDocumentPresentation();
    }
    
    var documentItemObject : FTDocumentItemWrapperObject {
        return self.documentViewController.shelfItemManagedObject;
    }
    
    var relativePath : String? {
        return documentViewController.pdfDocument.URL.relativePathWRTCollection()
    }
    
    func waitForTheDocmentToBeOpened() {
        self.documentViewController.waitForTheDocmentToBeOpened();
    }
    
    func insertNewPage(fromItem url:URL, onCompletion:((_ completed:Bool) -> Void)?) {
        documentViewController.insertNewPage(fromItem: url, onCompletion: onCompletion);
    }
    
    func addRecordingToPage(actionType: FTAudioActionType,
                            audio: FTAudioFileToImport,
                            onCompletion : ((Bool,NSError?) -> Void)?) {
        documentViewController.addRecordingToPage(actionType: actionType, audio: audio, onCompletion: onCompletion)
    }
    
    func didReceivePencilInteraction(_ action:FTApplePencilInteractionType) {
        (self.documentViewController as FTApplePencilInteractionProtocol).didReceivePencilInteraction?(action)
    }
    
    func startRecordingOnAudioNotebook() {
        self.documentViewController.audioButtonAction()
    }
        
    func saveApplicationStateByClosingDocument(_ shouldClose : Bool, keepEditingOn : Bool,onCompletion :((Bool) -> Void)?) {
        
        if !keepEditingOn {
            documentViewController.normalizeAndEndEditingAnnotation(true);
        }
        documentViewController.saveChanges(onCompletion: onCompletion,
                                     shouldCloseDocument: shouldClose,
                                     shouldGenerateThumbnail: false);
    }
    
    func canContinueToImportFiles() -> Bool {
        return documentViewController.canContinueToImportFiles()
    }
    
    func showAlertAskingToEnterPwdToContinueOperation() {
        documentViewController.showAlertAskingToEnterPwdToContinueOperation()
    }
    
    func avoidAskingPwd() {
        documentViewController.avoidAskingPwd()
    }
    
    func removeBlurEffectForPassword(_ animated : Bool) {
        documentViewController.removeBlurEffect(animated)
    }
}

extension FTDocumentRenderViewController: FTOpenCloseDocumentProtocol {
    func openRecentItem(shelfItemManagedObject: FTDocumentItemWrapperObject, addToRecent: Bool) {
        self.delegate?.openRecentItem(shelfItemManagedObject: shelfItemManagedObject, addToRecent: addToRecent)
    }
    
    func closeDocument(shelfItemManagedObject: FTDocumentItemWrapperObject, animate: Bool, onCompletion: (() -> Void)?) {
        self.delegate?.closeDocument(shelfItemManagedObject: shelfItemManagedObject, animate: animate, onCompletion: onCompletion)
    }
}

extension FTDocumentRenderViewController: FTDeskToolbarDelegate, FTDeskPanelActionDelegate {
    func currentDeskMode() -> RKDeskMode {
        return self.deskBarDelegate?.currentDeskMode() ?? .deskModePen
    }

    func lastSelectedPenMode() -> RKDeskMode {
        return self.deskBarDelegate?.lastSelectedPenMode() ?? .deskModePen
    }

    func shapesToolEnabled() -> Bool {
        return self.deskBarDelegate?.shapesToolEnabled() ?? false
    }

    func zoomModeEnabled() -> Bool {
        return self.deskBarDelegate?.zoomModeEnabled() ?? false
    }

    func canUndo() -> Bool {
        return self.deskBarDelegate?.canUndo?() ?? false
    }

    func undo() {
        self.deskBarDelegate?.undo?()
    }

    func canRedo() -> Bool {
        self.deskBarDelegate?.canRedo?() ?? false
    }

    func redo() {
        self.deskBarDelegate?.redo?()
    }

    func notebookTitle() -> NSString {
        return self.deskBarDelegate?.notebookTitle?() ?? NSString(string: "")
    }

    func didTapLeftPanelTool(_ buttonType: FTDeskLeftPanelTool, source: UIView) {
        self.deskPanelActionDelegate?.didTapLeftPanelTool(buttonType, source: source)
    }

    func didTapCenterPanelTool(_ buttonType: FTDeskCenterPanelTool, source: UIView) {
        self.deskPanelActionDelegate?.didTapCenterPanelTool(buttonType, source: source)
    }

    func didTapRightPanelTool(_ buttonType: FTDeskRightPanelTool, source: UIView, mode: FTScreenMode) {
        self.deskPanelActionDelegate?.didTapRightPanelTool(buttonType, source: source, mode: mode)
    }
}

extension FTDocumentRenderViewController: FTTextToolbarControllerDelegate {
    func didAddTextToolBar(_ controller: FTTextToolBarViewController) {
        resetTextmodeInputView()
        if let annot = controller.toolBarDelegate as? FTTextAnnotationViewController {
#if targetEnvironment(macCatalyst)
            let container = self.prepareAndFetchTextToolbarContainer()
            controller.view.addFullConstraints(container)
#else
            controller.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: textToolbarHeight)
            annot.textInputView.inputAccessoryView = controller.view
            self.toolBarView?.isHidden = false
#endif
        }
        self.textToolbarController = controller
        self.textToolbarController?.documentRenderVC = self
        self.textToolbarController?.switchMode()
    }
    
    func didRemoveTextToolBar() {
        if let toolBarView = self.textToolbarController?.view {
            self.textToolbarController?.removeFromParent()
            self.textToolbarController?.view.removeFromSuperview()
            self.textToolbarController = nil
            self.toolBarView?.isHidden = false
#if targetEnvironment(macCatalyst)
            self.view.viewWithTag(textContainerTag)?.removeFromSuperview()
#endif
        }
    }
    
    private func resetTextmodeInputView() {
        self.didRemoveTextToolBar()
    }
}


#if targetEnvironment(macCatalyst)
extension FTDocumentRenderViewController {
    func prepareAndFetchTextToolbarContainer() -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.tag = textContainerTag
        self.view.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
        container.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0).isActive = true
        container.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        container.heightConst(textToolbarHeight)
        return container
    }
}
#endif
