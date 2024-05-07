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
        let interaction = UIEditMenuInteraction(delegate: self)
        self.view.addInteraction(interaction)
        self.interaction = interaction
        self.editMenuConfig = UIEditMenuConfiguration(identifier: "TextLongPressMenu", sourcePoint: self.textInputView.frame.origin)
        interaction.presentEditMenu(with: editMenuConfig!)
        #endif
    }
        
    private func isToHidePasteOption() -> Bool {
        var toHidePaste: Bool = true
        if let content = UIPasteboard.general.string, content != "" {
            toHidePaste = false
        }
        return toHidePaste
    }

    internal func getMenuItemsForLongPress() -> [UIAction] {
        guard let baseView = self.view as? FTAnnotationBaseView else {
            return []
        }
        let editAction = UIAction(title: "Edit".localized) { action in
            baseView.editMenuItemAction(action)
        }
        let cutAction = UIAction(title: "Cut".localized) { action in
            baseView.cutMenuItemAction(action)
        }
        let copyAction = UIAction(title: "Copy".localized) { action in
            baseView.copyMenuItemAction(action)
        }
        let lockAction = UIAction(title: "Lock".localized) { action in
            baseView.lockMenuItemAction(action)
        }
        let deleteAction = UIAction(title: "Delete".localized) { action in
            baseView.deleteMenuItemAction(action)
        }
        let editLinkAction = UIAction(title: "textLink_editLink".localized) { action in
            baseView.editLinkMenuItemAction(action)
        }
        let deleteLinkAction = UIAction(title: "textLink_removeLink".localized) { action in
            baseView.removeLinkMenuItemAction(action)
        }
        let linkAction = UIAction(title: "textLink_linkTo".localized) { action in
            baseView.linkToMenuItemAction(action)
        }
        let bringToFrontAction = UIAction(title: "BringToFront".localized) { action in
            baseView.bringToFrontMenuItemAction(action)
        }
        let sendToBackAction = UIAction(title: "SendToBack".localized) { action in
            baseView.sendToBackMenuItemAction(action)
        }
        var actions: [UIAction] = [
            editAction,
            cutAction,
            copyAction,
            deleteAction,
            lockAction
        ]
        if self.textInputView?.checkIfToShowEditLinkOptions() ?? false {
            actions.append(contentsOf: [editLinkAction, deleteLinkAction])
        } else {
            actions.append(linkAction)
        }
        actions.append(contentsOf: [bringToFrontAction, sendToBackAction])
#if DEBUG
        let convertAction = UIAction(title: "Conver to stroke".localized) { action in
            baseView.convertToStroke(action)
        }
        actions.append(convertAction)
#endif
        return actions
    }

    @objc internal func performLinkAction(_ sender: Any?) {
        self.linkSelectedRange = self.textInputView.selectedRange
        if self.linkSelectedRange?.length == 0 {
            self.linkSelectedRange = NSRange(location: 0, length: self.textInputView.attributedText.length)
        }
        guard let attrText = self.textInputView.attributedText, let reqRange = self.linkSelectedRange else {
            return
        }
        if let annotation = self.annotation as? FTTextAnnotation, let curPage = annotation.associatedPage {
            var linkText: String
            if reqRange.length > 0 {
                linkText = (attrText.string as NSString).substring(with: reqRange)
            } else {
                linkText = attrText.string
            }

            let attrs = attrText.attributes(at: reqRange.location, effectiveRange: nil)
            var url: URL?
            if let schemeUrl = attrs[.link] as? URL {
                url = schemeUrl
            }
            self.transitionInProgress = true
            FTLinkToSelectViewController.showTextLinkScreen(from: self, linkText: linkText, url: url, currentPage: curPage)
        }
    }

    @objc internal func removeLinkAction(_ sender: Any?) {
        var range = self.linkSelectedRange ?? self.textInputView.selectedRange
        if range.length == 0 { // long pressed text
            range = NSRange(location: 0, length: self.textInputView.attributedText.length)
        }
        self.textInputView.setValueFor(nil, forAttribute: NSAttributedString.Key.link.rawValue, in: range)
        let keys = NSAttributedString.linkAttributes.keys
        keys.forEach { attr in
            self.textInputView.setValueFor(nil, forAttribute: attr.rawValue, in: range)
        }
        self.saveTextEntryAttributes()
    }

    private func updateLinkAttribute(with url: URL, text: String) {
        guard let attrText = self.textInputView.attributedText?.mutableCopy() as? NSMutableAttributedString, !text.isEmpty, let exstRange = self.linkSelectedRange else {
            return
        }
        let originalAttributes = attrText.attributes(at: exstRange.location, effectiveRange: nil)
        attrText.replaceCharacters(in: exstRange, with: "")
        let newAttrStr = NSAttributedString(string: text, attributes: originalAttributes)
        attrText.insert(newAttrStr, at: exstRange.location)
        let newRange = NSRange(location: exstRange.location, length: (text as NSString).length)
        attrText.removeAttribute(.link, range: newRange)
        attrText.addAttribute(.link, value: url, range: newRange)
        attrText.addAttributes(NSAttributedString.linkAttributes, range: newRange)
        self.textInputView.attributedText = attrText
        self.transitionInProgress = false
        self.handleLinkTextEditUpdate()
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
        let contentSize = editMode.contentSize
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
        // To fix the issue of unlock menu items shown after immediate unlock of text annotation.
        // After complete refactor of UIMenitem, controller, below condition can be removed
        if !(UIMenuController.shared.menuItems?.isEmpty ?? false), self.isEditMode {
            UIMenuController.shared.menuItems = []
        }
        if [#selector(view.editMenuItemAction(_:)), #selector(view.cutMenuItemAction(_:)), #selector(view.copyMenuItemAction(_:)), #selector(view.lockMenuItemAction(_:)),
            #selector(view.copyMenuItemAction(_:)), #selector(view.convertToStroke(_:)),
            #selector(view.bringToFrontMenuItemAction(_:)), #selector(view.sendToBackMenuItemAction(_:)), #selector(view.deleteMenuItemAction(_:))].contains(action) {
            return true
        } else if self.textInputView.checkIfToShowEditLinkOptions() {
            if [#selector(view.editLinkMenuItemAction(_:)), #selector(view.removeLinkMenuItemAction(_:))].contains(action) {
                // To avoid duplicate track of - pageLinkLongPress event
                // added one more condition
                if [#selector(view.editLinkMenuItemAction(_:))].contains(action) {
                    FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.pageLinkLongPress)
                }
                return true
            }
        } else if [#selector(view.linkToMenuItemAction(_:))].contains(action) {
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

        case .linkTo, .editLink:
            self.textInputView.linkMenuItemAction(sender)

        case .removeLink:
            self.textInputView.removeLinkMenuItemAction(sender)

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

extension FTTextAnnotationViewController: FTTextLinkEditDelegate {
    func updateTextLinkInfo(_ info: FTPageLinkInfo, text: String) {
        guard !text.isEmpty else {
            return
        }
        if let url = URL(docId: info.docUUID, pageId: info.pageUUID) {
            self.updateLinkAttribute(with: url, text: text)
        }
    }
    
    func updateWebLink(_ url: URL, text: String) {
        guard !text.isEmpty else {
            return
        }
        self.updateLinkAttribute(with: url, text: text)
    }
}

#if !targetEnvironment(macCatalyst)
extension FTTextAnnotationViewController: UIEditMenuInteractionDelegate {
    func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
        let menuItems = self.getMenuItemsForLongPress()
        return UIMenu(title: "", children: menuItems)
    }
}
#endif
