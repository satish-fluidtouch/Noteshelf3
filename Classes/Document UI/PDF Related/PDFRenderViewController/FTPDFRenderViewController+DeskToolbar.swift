//
//  FTPDFRenderViewController+DeskToolbar.swift
//  Noteshelf3
//
//  Created by Narayana on 19/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

@objc protocol FTFinderNotifier: AnyObject {
    func didAddPage()
    func didBookmarkPage()
    func didTagPage()
    func didRotatePage()
    func didDuplicatePage()
    func willEnterIntoEditmode()
    func didGoToAudioRecordings(with annotation: FTAnnotation)
    func didCloseNotebook();
}

#if targetEnvironment(macCatalyst)
typealias FTBackSourceItem = NSToolbarItem;
typealias FTCenterToolSourceItem = NSToolbarItem;
#else
typealias FTBackSourceItem = UIView;
typealias FTCenterToolSourceItem = UIView;
#endif

extension FTPDFRenderViewController {
    func leftPanelToolbarSource(for type:FTDeskLeftPanelTool) -> UIView? {
        guard let parentController = self.parent as? FTToolbarElements else { return nil }
        return parentController.toolbarSourceView(for: type)
    }

    @objc func centerPanelToolbarSource(for type:FTDeskCenterPanelTool) -> UIView? {
        guard let parentController = self.parent as? FTToolbarElements else { return nil }
        return parentController.toolbarSourceView(for: type)
    }

    @objc func rightPanelSource(for type:FTDeskRightPanelTool) -> UIView? {
        guard let parentController = self.parent as? FTToolbarElements else { return nil }
        return parentController.toolbarSourceView(for: type)
    }
}

extension FTPDFRenderViewController: FTDeskPanelActionDelegate {
    func didTapLeftPanelTool(_ buttonType: FTDeskLeftPanelTool, source:UIView) {
        #if !targetEnvironment(macCatalyst)
        FTQuickPageNavigatorViewController.hidePageNavigator(forController: self)
        FTRefreshViewController.addObserversForHideNewPageOptions()
        switch buttonType {
        case .back:
            self.backButtonAction(with: source)
            FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.toolbar_back_tap)
            break
        case .finder:
            self.finderButtonAction(true)
            break
        default:
            break
        }
        #endif
    }
    
    func backButtonAction(with source: FTBackSourceItem) {
        if self.pdfDocument.isJustCreatedWithQuickNote == false {
            self.back(toShelfButtonAction: FTNormalAction, with: shelfItemManagedObject.title)
        } else {
            self.normalizeAndEndEditingAnnotation(true);
            if self.pdfDocument.isDirty == false {
                self.back(toShelfButtonAction: FTDeletePermanentlyAction, with: shelfItemManagedObject.title)
            } else {
                self.showQuickNoteSaveControllerIfNeeded(sourceView: source)
            }
        }
    }

    func didTapCenterPanelTool(_ buttonType: FTDeskCenterPanelTool, source:UIView) {
#if !targetEnvironment(macCatalyst)
        FTQuickPageNavigatorViewController.hidePageNavigator(forController: self)
        FTRefreshViewController.addObserversForHideNewPageOptions()
        
        switch buttonType {
        case .pen:
            self.penButtonAction(source)
            
        case .highlighter:
            self.markerButtonAction(source)

        case .eraser:
            self.eraserButtonAction(source)

        case .shapes:
            self.shapesButtonAction(source)

        case .textMode:
            self.textButtonAction()
            
        case .presenter:
            self.readOnlyModeisOn = false
            self.presenterButtonAction()
            
        case .lasso:
            self.lassoButtonAction(source)

        case .favorites:
            self.favoritesButtonAction(source)
            
        case .photo:
            self.executer?.execute(type: .photo)
            
        case .audio:
            self.executer?.execute(type: .audio)
            
        case .rotatePage:
            self.executer.execute(type: .rotatePage(angle: FTPageRotation.nintetyClockwise.rawValue))
            self.finderNotifier?.didRotatePage()
            let config = FTToastConfiguration(title: "shortcut.toast.rotatePage".localized)
            FTToastHostController.showToast(from: self, toastConfig: config)
            
        case .bookmark:
            if let currentPage = self.currentlyVisiblePage() as? FTThumbnailable {
                self.executer.execute(type: .bookmark(page: currentPage))
                self.finderNotifier?.didBookmarkPage()
                let title: String
                if currentPage.isBookmarked {
                    title = "shortcut.toast.bookmarkPage".localized
                } else {
                    title = "shortcut.toast.removePageFromBookmarks".localized
                }
                let config = FTToastConfiguration(title: title)
                FTToastHostController.showToast(from: self, toastConfig: config)
            }
            
        case .page:
            self.executer.execute(type: .addPage)
            self.finderNotifier?.didAddPage()
            let config = FTToastConfiguration(title: "shortcut.toast.addPage".localized)
            FTToastHostController.showToast(from: self, toastConfig: config)
            
        case .duplicatePage:
            if let page = self.firstPageController()?.pdfPage as? FTThumbnailable {
                self.executer.execute(type: .duplicatePage(pages: [page])) {
                    self.finderNotifier?.didDuplicatePage()
                    let config = FTToastConfiguration(title: "shortcut.toast.duplicatePage".localized)
                    FTToastHostController.showToast(from: self, toastConfig: config)
                }
            }

        case .deletePage:
            if let page = self.firstPageController()?.pdfPage as? FTThumbnailable {
                self.executer.execute(type: .deletePage(page: page))
            }

        case .tag:
            if let page = self.firstPageController()?.pdfPage as? FTThumbnailable {
                let pagesSet = NSSet(array: [page])
                self.executer.execute(type: .tag(source: source, controller: self, pages: pagesSet))
            }
        case .camera :
            self.executer?.execute(type: .camera)
        case .scrolling :
            let oppLayout = UserDefaults.standard.pageLayoutType.oppositeLayout
            self.executer?.execute(type: .scrolling(source: oppLayout))
            let layout = UserDefaults.standard.pageLayoutType
            let config = FTToastConfiguration(title: layout.toastTitle.localized)
            FTToastHostController.showToast(from: self, toastConfig: config)
            layout.trackLayout()
        case .recentNotes:
            self.executer.execute(type: .recentNotes(source: source))
        case .unsplash:
            self.executer.execute(type: .unsplash(source: source))
            
        case .pixabay:
            self.executer.execute(type: .pixabay(source: source))
            
        case .emojis:
            self.executer.execute(type: .emojis(source: source))
        case .stickers:
            self.executer.execute(type: .stickers(source: source))
        case .savedClips:
            self.executer.execute(type: .savedClips(source: source))
            
        case .zoomBox:
            self.zoomButtonAction()
            
        case .hand:
            let config = FTToastConfiguration(title: "customizeToolbar.readOnlyMode".localized)
            FTToastHostController.showToast(from: self, toastConfig: config)
            self.readOnlyButtonAction()
            
        case .share:
            self.showShareOptions(with: source)
            
        case .shareNotebookAsPDF:
            self.executer.execute(type: .shareNoteBookAsPDF(source: source))
            
        case .sharePageAsPng:
            self.executer.execute(type: .sharePageAsPng(source: source))
            
        case .savePageAsPhoto:
            self.executer.execute(type: .savePageAsPhoto)
            
        case .openAI:
            self.firstPageController()?.startOpenAiForPage();
        default:
            break
        }
#endif
    }

    func didTapRightPanelTool(_ buttonType: FTDeskRightPanelTool, source: UIView, mode: FTScreenMode) {
        FTQuickPageNavigatorViewController.hidePageNavigator(forController: self)
        FTRefreshViewController.addObserversForHideNewPageOptions()
        switch buttonType {
        case .add:
            self.addAnnotationButtonAction(source: source)
            FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.toolbar_addmenu_tap)
            break
        case .share:
            break
        case .more:
            self.settingsButtonAction()
            FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.toolbar_more_tap)
            break
        case .focus:
            self.handleFocusModeAction(mode: mode)
        }
    }

    func handleFocusModeAction(mode: FTScreenMode) {
        UIView.animate(withDuration: 0.3) {
            if nil != self.zoomOverlayController {
                self.delayedZoomButtonAction()
            }
        } completion: { _  in
            self.showOrHideShortcutViewIfNeeded(mode)
            self.performLayout()
        }
        self.updatePageNumberLabelFrame()
    }
    
    @objc func deskToolBarFrame() -> CGRect {
#if !targetEnvironment(macCatalyst)
        if let documentController = self.parent as? FTDocumentRenderViewController {
            return documentController.deskToolBarFrame()
        }
        return CGRect.zero
#else
        return CGRect.zero
#endif
    }
    
    @objc func deskToolBarHeight() -> CGFloat {
    #if !targetEnvironment(macCatalyst)
        if let documentController = self.parent as? FTDocumentRenderViewController {
            return documentController.deskToolBarHeight()
        }
        return CGFloat.zero
    #else
        return CGFloat.zero
    #endif
    }

    @objc func toolBarState() -> FTScreenMode {
        if let documentController = self.parent as? FTDocumentRenderViewController {
            return documentController.currentToolBarState()
        }
        return .normal
    }
}

extension FTPDFRenderViewController {
    func getFinderViewController() {

    }
}

extension FTPDFRenderViewController: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let aSet = CharacterSet(charactersIn:"0123456789").inverted
        let compSepByCharInSet = string.components(separatedBy: aSet)
        let numberFiltered = compSepByCharInSet.joined()
        var isValid = (string == numberFiltered)
        if isValid, !string.isEmpty, let numberText = textField.text {
            guard let textRange = Range(range, in: numberText) else { return false }
            let numberText = textField.text?.replacingCharacters(in: textRange, with: string)
            if let pageNumber = (numberText as NSString?)?.integerValue, (pageNumber < 1 || pageNumber > self.pdfDocument.pages().count) {
                isValid = false
            }
        }
        return isValid
    }
}
extension FTPDFRenderViewController {
    @objc func getTopOffset() -> CGFloat {
        let yPadding: CGFloat = FTToolBarConstants.subtoolbarOffset
        var offset: CGFloat = 0.0
        if self.currentToolBarState() == .shortCompact {
            var extraHeight: CGFloat = 0.0
            if UIDevice.current.isPhone() {
                if let window = UIApplication.shared.keyWindow {
                    let topSafeAreaInset = window.safeAreaInsets.top
                    if topSafeAreaInset > 0 {
                        extraHeight = topSafeAreaInset
                    }
                }
            }
            offset = FTToolbarConfig.Height.compact + extraHeight + yPadding
        } else if self.currentToolBarState() == .normal {
#if targetEnvironment(macCatalyst)
            offset = 0.0 + yPadding
#else
            offset = self.deskToolBarFrame().maxY + yPadding
#endif
        } else {
            offset = FTToolBarConstants.yOffset + FTToolBarConstants.statusBarOffset;
        }
        return offset
    }
}

extension FTPDFRenderViewController: FTFavoriteSizeEditDelegate, FTFavoriteColorEditDelegate, FTShapeShortcutEditDelegate, FTFavoriteColorNotifier, FTPresenterShortcutDelegate {
    func showShapeEditScreen(position: FavoriteShapePosition) {
        
    }
    
    func didSelectFavoriteShape(_ shape: FTShapeType) {
        
    }
    
    func showSizeEditScreen(position: FavoriteSizePosition, viewModel: FTFavoriteSizeViewModel) {
        
    }
    
    func showEditColorScreen(using rack: FTRackData, position: FavoriteColorPosition, rect: CGRect) {
        let viewModel = FTPenShortcutViewModel(rackData: rack)
        let hostingVc = FTPenColorEditController(viewModel: viewModel, delegate: self)
//        self.penShortcutViewModel = viewModel
        let flow = FTColorsFlowType.penType(rack.currentPenset.type)
        let editMode = FTPenColorSegment.savedSegment(for: flow)
        let contentSize = editMode.contentSize
        hostingVc.ftPresentationDelegate.source = self.view
        hostingVc.ftPresentationDelegate.sourceRect = rect
        hostingVc.ftPresentationDelegate.permittedArrowDirections = .any
        self.ftPresentPopover(vcToPresent: hostingVc, contentSize: contentSize, hideNavBar: true)
    }
    
    func saveFavoriteColorsIfNeeded() {
        self.colorModel?.updateCurrentFavoriteColors()
    }
    
    func didChangeCurrentPenset(_ penset: FTPenSetProtocol, dismissSizeEditView: Bool) {
        var rackType = FTRackType.pen
        if self.currentDeskMode == .deskModeMarker {
            rackType = .highlighter
        } else if  self.currentDeskMode == .deskModeShape {
            rackType = .shape
        }
        let rackData = FTRackData(type: rackType, userActivity: self.view.window?.windowScene?.userActivity)
            rackData.currentPenset.color = penset.color
            rackData.currentPenset.size = penset.size
            rackData.currentPenset.preciseSize = penset.preciseSize
            rackData.saveCurrentSelection()
            self.validateMenuItems()
    }
    
    func didSelectColorFromEditScreen(_ penset: FTPenSetProtocol) {
        self.colorModel?.updateFavoriteColor(with: penset.color)
        self.didChangeCurrentPenset(penset, dismissSizeEditView: false)
    }

    func didChangeCurrentPresenterSet(_ presenterSet: FTPresenterSetProtocol) {

    }
}

class TransparentTouchView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        print("&&& ", self.layer.sublayers?.first as? CAShapeLayer)
        if let layer = self.layer.sublayers?.first as? CAShapeLayer , let path = layer.path, path.contains(point) {
            print("&&& Contains point")
            return hitView
        }
        print("&&& Nil")
        return nil
    }
}


extension CGPath {
    func contains(_ point: CGPoint) -> Bool {
        return self.contains(point, using: .evenOdd, transform: .identity)
    }
}
