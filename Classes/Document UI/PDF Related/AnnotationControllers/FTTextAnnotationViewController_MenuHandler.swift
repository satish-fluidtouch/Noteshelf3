//
//  FTTextAnnotationViewController_MenuHandler.swift
//  Noteshelf
//
//  Created by Narayana on 08/07/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import MobileCoreServices

extension FTTextAnnotationViewController {
    
    override func canPerformAction(_ action: Selector, withSender sender: Any!) -> Bool {
        return false
    }
    
    internal func setupMenuForTextViewLongPress() {
        #if !targetEnvironment(macCatalyst)
        self.view.becomeFirstResponder()
        let menuController = UIMenuController.shared
        let menuItems = self.getMenuItemsForLongPress()
        menuController.menuItems = menuItems
        menuController.showMenu(from: self.textInputView, rect: self.textInputView.frame)
        #endif
    }
        
    private func isToHidePasteOption() -> Bool {
        var toHidePaste: Bool = true
        if let content = UIPasteboard.general.string, content != "" {
            toHidePaste = false
        }
        return toHidePaste
    }

    
    internal func getMenuItemsForLongPress() -> [UIMenuItem] {
        let editMenuItem: UIMenuItem = UIMenuItem(title: NSLocalizedString("Edit", comment: "Edit"), action: #selector(FTAnnotationBaseView.editMenuItemAction(_:)))
        let cutMenuItem: UIMenuItem = UIMenuItem(title: NSLocalizedString("Cut", comment: "Cut"), action: #selector(FTAnnotationBaseView.cutMenuItemAction(_:)))
        let copyMenuItem: UIMenuItem = UIMenuItem(title: NSLocalizedString("Copy", comment: "Copy"), action: #selector(FTAnnotationBaseView.copyMenuItemAction(_:)))
        let lockMenuItem: UIMenuItem = UIMenuItem(title: NSLocalizedString("Lock", comment: "Lock"), action: #selector(FTAnnotationBaseView.lockMenuItemAction(_:)))
//        let removeLinkMenuItem: UIMenuItem = UIMenuItem(title: "Remove Link/s", action: #selector(FTAnnotationBaseView.removeLinkMenuItemAction(_:)))
        let bringToFrontMenuItem: UIMenuItem = UIMenuItem(title: NSLocalizedString("BringToFront", comment: "BringToFront"), action: #selector(FTAnnotationBaseView.bringToFrontMenuItemAction(_:)))
        let sendToBackMenuItem: UIMenuItem = UIMenuItem(title: NSLocalizedString("SendToBack", comment: "SendToBack"), action: #selector(FTAnnotationBaseView.sendToBackMenuItemAction(_:)))
        let deleteMenuItem: UIMenuItem = UIMenuItem(title: NSLocalizedString("Delete", comment: "Delete"), action: #selector(FTAnnotationBaseView.deleteMenuItemAction(_:)))

        var menuItems: [UIMenuItem] = [
            editMenuItem
            , cutMenuItem
            , copyMenuItem
            , deleteMenuItem
            , lockMenuItem
            , bringToFrontMenuItem
            , sendToBackMenuItem
        ]
        #if DEBUG
        let convertMenuItem: UIMenuItem = UIMenuItem(title: "Conver to stroke", action: #selector(FTAnnotationBaseView.convertToStroke(_:)))
        menuItems.append(convertMenuItem);
        #endif
        return menuItems
    }
    
    @objc internal func performLinkAction(_ sender: Any?) {
        self.linkSelectedRange = self.textInputView.selectedRange
        guard let attrText = self.textInputView.attributedText, let reqRange = self.linkSelectedRange else {
            return
        }
        let attrs = attrText.attributes(at: reqRange.location, effectiveRange: nil)
        if let schemeUrl = attrs[.link] as? URL, let documentId = FTTextLinkRouteHelper.getQueryItems(of: schemeUrl).docId {
            let textLinkVc = FTTextLinkViewController.showTextLinkScreen(from: self, source: self.textInputView, with: documentId)
            textLinkVc?.delegate = self
            textLinkVc?.pageDelegate = self
        } else {
            if let annotation = self.annotation as? FTTextAnnotation, let curPage = annotation.associatedPage, let doc = curPage.parentDocument {
                if let url = FTTextLinkRouteHelper.getLinkUrlForTextView(using: doc.documentUUID, pageId: curPage.uuid) {
                    // Add with current info
                    self.updateLinkAttribute(with: url, for: reqRange)
                    // Edit screen
                    let textLinkVc = FTTextLinkViewController.showTextLinkScreen(from: self, source: self.textInputView, with: doc.documentUUID)
                    textLinkVc?.delegate = self
                    textLinkVc?.pageDelegate = self
                }
            }
        }
    }

    private func updateLinkAttribute(with url: URL, for range: NSRange) {
        guard let attrText = self.textInputView.attributedText else {
            return
        }
        let attributedString: NSMutableAttributedString = NSMutableAttributedString(attributedString: attrText)
        attributedString.removeAttribute(.link, range: range)
        attributedString.addAttribute(.link, value: url, range: range)
        attributedString.addAttributes(NSAttributedString.linkAttributes, range: range)
        self.textInputView.attributedText = attributedString
        self.saveTextEntryAttributes()
    }
    
    @objc internal func performLookUpMenu(_ sender: Any?) {
        if let selectedText: String = self.textInputView.getSelectedText(), !selectedText.isEmpty {
            self.presentLookUpScreen(selectedText)
        }
    }
    
    @objc internal func performShareMenu(_ sender: Any?) {
        if let selectedText: String = self.textInputView.getSelectedText(), !selectedText.isEmpty {
            let activityViewController = UIActivityViewController(activityItems: [selectedText], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.excludedActivityTypes = [.airDrop, .postToFacebook]
            self.present(activityViewController, animated: true, completion: nil)
        }
    }

    @objc internal func performColorMenu(_ sender: Any?) {
        let rackData = FTRackData(type: .pen, userActivity: self.view.window?.windowScene?.userActivity)
        let editMode = FTPenColorSegment.savedSegment(for: .text)
        var contentSize = FTPenColorEditController.presetViewSize
        if editMode == .grid {
            contentSize = FTPenColorEditController.gridViewSize
        }
        let model = FTPenShortcutViewModel(rackData: rackData)
        let hostingVc = FTPenColorEditController(viewModel: model, delegate: self)
        self.penShortcutViewModel = model
        hostingVc.ftPresentationDelegate.source = self.textInputView
        hostingVc.ftPresentationDelegate.sourceRect = self.textInputView.frame
        self.ftPresentPopover(vcToPresent: hostingVc, contentSize: contentSize, hideNavBar: true)
    }

    @objc internal func performMoveToFrontMenu(_ sender: Any?) {
        self.delegate?.moveAnnotationToFront(self.annotation)
    }
    
    @objc internal func performMoveToBackMenu(_ sender: Any?) {
        self.delegate?.moveAnnotationToBack(self.annotation)
    }

    @objc internal func performCopyOperationForLongPress(_ sender: Any?) {
        let pasteboard = UIPasteboard.general
        // To have proviosion of pasting the text outside application
        do {
            self.annotation.copyMode = true
            let annotationData = try NSKeyedArchiver.archivedData(withRootObject: self.annotation, requiringSecureCoding: false)
            self.annotation.copyMode = false
            var pbInfo: [String: Any] = [String: Any]()
            pbInfo[UIPasteboard.pdfAnnotationUTI()] = annotationData
            if let textAnnotation = self.annotation as? FTTextAnnotation, let text = textAnnotation.attributedString {
                pbInfo[kUTTypeUTF8PlainText as String] = text.string;
            }
            pasteboard.items = [pbInfo];
        }
        catch {
            print("error description: \(error.localizedDescription)")
        }
    }
}

extension FTTextAnnotationViewController: FTTextMenuActionProtocol {
    
    func canPerformAction(view: FTAnnotationBaseView, action: Selector, withSender sender: Any!) -> Bool {
        if [#selector(view.editMenuItemAction(_:)), #selector(view.cutMenuItemAction(_:)), #selector(view.copyMenuItemAction(_:)), #selector(view.lockMenuItemAction(_:)),
            #selector(view.copyMenuItemAction(_:)), #selector(view.convertToStroke(_:)),
            /*#selector(view.removeLinkMenuItemAction(_:)),*/ #selector(view.bringToFrontMenuItemAction(_:)), #selector(view.sendToBackMenuItemAction(_:)), #selector(view.deleteMenuItemAction(_:))].contains(action) {
            return true
        }
        return false
    }
    
    func textMenuAction(action: FTTextMenuAction, sender: Any?) {
        switch action {
        case .edit:
            track("textbox_edit_tapped", params: [:], screenName: FTScreenNames.textbox)
            self.handleEditMenuActionForLongPress()
            
        case .cut:
            track("textbox_cut_tapped", params: [:], screenName: FTScreenNames.textbox)
            self.performCopyOperationForLongPress(sender)
            self.delegate?.annotationControllerDidRemoveAnnotation(self, annotation: self.annotation)

        case .copy:
            track("textbox_copy_tapped", params: [:], screenName: FTScreenNames.textbox)
            self.performCopyOperationForLongPress(sender)
            self.delegate?.annotationControllerDidCancel(self)

        case .lock:
            track("textbox_lock_tapped", params: [:], screenName: FTScreenNames.textbox)
            self.annotation.isLocked = true
            self.endEditingAnnotation()
            self.delegate?.annotationControllerDidCancel(self)

        case .bringToFront:
            track("textbox_bringtofront_tapped", params: [:], screenName: FTScreenNames.textbox)
            self.performMoveToFrontMenu(sender)

        case .sendToBack:
            track("textbox_sendtoback_tapped", params: [:], screenName: FTScreenNames.textbox)
            self.performMoveToBackMenu(sender)

        case .delete:
            track("textbox_delete_tapped", params: [:], screenName: FTScreenNames.textbox)
            self.textInputView.delete(sender)
            self.delegate?.annotationControllerDidRemoveAnnotation(self, annotation: self.annotation)
        case .converToStroke:
            track("textbox_delete_tapped", params: [:], screenName: FTScreenNames.textbox)
            self.endEditingAnnotation()
            self.delegate?.convertToStroke?(self, annotation: self.annotation)
        }
    }
    
}

extension FTTextAnnotationViewController: FTFavoriteColorNotifier {
    func didSelectColorFromEditScreen(_ penset: FTPenSetProtocol)  {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateTextcolor(_:)), object: nil)
        self.perform(#selector(updateTextcolor(_ :)), with: penset.color, afterDelay: 0.1)
    }

    @objc func updateTextcolor(_ hex: String) {
        let color = UIColor(hexString: hex)
        self.setTextColor(color, in: self.textInputView.selectedRange)
    }
}

extension FTTextAnnotationViewController: FTColorEyeDropperPickerDelegate {
    func colorPicker(picker: FTColorEyeDropperPickerController,didPickColor color:UIColor) {
        self.updateTextcolor(color.hexString)
        if let shortcutVm = self.penShortcutViewModel {
            if let editIndex = shortcutVm.presetEditIndex {
                shortcutVm.updatePresetColor(hex: color.hexString, index: editIndex)
                NotificationCenter.default.post(name: .PresetColorUpdate, object: nil, userInfo: ["type": FTColorToastType.edit.rawValue])
            } else {
                shortcutVm.addSelectedColorToPresets()
                NotificationCenter.default.post(name: .PresetColorUpdate, object: nil, userInfo: ["type": FTColorToastType.add.rawValue])
            }
            shortcutVm.updateCurrentColors()
        }
        self.penShortcutViewModel = nil
    }
}

#if targetEnvironment(macCatalyst)
extension FTTextAnnotationViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        if (self.isEditMode) {
            return nil
        }
        let actionProvider : ([UIMenuElement]) -> UIMenu? = {[weak self] _ in
            var menuItems = [UIMenuElement]();
            
            let editmenu = UIAction(title: NSLocalizedString("Edit", comment: "Edit")) { [weak self] _  in
                self?.textMenuAction(action: .edit, sender: nil);
            }
            menuItems.append(editmenu);
            
            let cutMenuItem = UIAction(title: NSLocalizedString("Cut", comment: "Cut")) { [weak self] _  in
                self?.textMenuAction(action: .cut, sender: nil);
            }
            menuItems.append(cutMenuItem);

            let copyMenuItem = UIAction(title: NSLocalizedString("Copy", comment: "Copy")) { [weak self] _  in
                self?.textMenuAction(action: .copy, sender: nil);
            }
            menuItems.append(copyMenuItem);

            let deleteMenuItem = UIAction(title: NSLocalizedString("Delete", comment: "Delete")) { [weak self] _  in
                self?.textMenuAction(action: .delete, sender: nil);
            }
            menuItems.append(deleteMenuItem);

            let lockMenuItem = UIAction(title: NSLocalizedString("Lock", comment: "Lock")) { [weak self] _  in
                self?.textMenuAction(action: .lock, sender: nil);
            }
            menuItems.append(lockMenuItem);

            let bringToFrontMenuItem = UIAction(title: NSLocalizedString("BringToFront", comment: "BringToFront")) { [weak self] _  in
                self?.textMenuAction(action: .bringToFront, sender: nil);
            }
            menuItems.append(bringToFrontMenuItem);

            let sendToBackMenuItem = UIAction(title: NSLocalizedString("SendToBack", comment: "SendToBack")) { [weak self] _  in
                self?.textMenuAction(action: .sendToBack, sender: nil);
            }
            menuItems.append(sendToBackMenuItem);

            let menu = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: menuItems);
            return menu;
        }
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: actionProvider)
        return config
    }
}

#endif

extension FTTextAnnotationViewController: FTDocumentSelectionDelegate, FTPageSelectionDelegate {
    func didSelect(document: FTShelfItemProtocol) {
        let range = self.linkSelectedRange ?? self.textInputView.selectedRange
        if let doc = document as? FTDocumentItemProtocol, let docId = doc.documentUUID, let url = FTTextLinkRouteHelper.getLinkUrlForTextView(using: docId, pageId: "FirstPage") {
            self.updateLinkAttribute(with: url, for: range)
        }
    }
    
    func didSelect(page: FTNoteshelfPage) {
        let range = self.linkSelectedRange ?? self.textInputView.selectedRange
        print("zzzz - range: \(range)")
        if let attrText = self.textInputView.attributedText {
            let attrs = attrText.attributes(at: range.location, effectiveRange: nil)
            if let schemeUrl = attrs[.link] as? URL, let documentId = FTTextLinkRouteHelper.getQueryItems(of: schemeUrl).docId,
               let reqUrl = FTTextLinkRouteHelper.getLinkUrlForTextView(using: documentId, pageId: page.uuid) {
                self.updateLinkAttribute(with: reqUrl, for: range)
            }
        }
    }
}
