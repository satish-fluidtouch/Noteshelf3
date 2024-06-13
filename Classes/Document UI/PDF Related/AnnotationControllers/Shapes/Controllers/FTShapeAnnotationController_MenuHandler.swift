//
//  FTShapeAnnotationController_MenuHandler.swift
//  Noteshelf
//
//  Created by Sameer on 20/01/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
extension FTShapeAnnotationController {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        var retValue = super.canPerformAction(action, withSender: sender);
        if action == #selector(self.cutMenuAction(_:))
            || action == #selector(self.copyMenuAction(_:)) {
            retValue = true
        }
        else if action == #selector(self.deleteMenuAction(_:)) {
            retValue = true
        }   else if action == #selector(self.lockMenuAction(_:)) {
            retValue = self.allowsLocking
        }
        return retValue;
    }
    
    func showMenu(_ show: Bool) {
        if show {
            if let resizableView = resizableView {
                var frame = resizableView.frame
                frame.origin.y -= 10
                showMenuFrom(rect: frame)
            }
        } else {
            hideMenu()
        }
    }
    
    func hideMenu() {
        UIMenuController.shared.hideMenu()
    }
    
    private func showMenuFrom(rect: CGRect) {
        if (rect == CGRect.null || rect.size == .zero) {
            return
        }
        #if !targetEnvironment(macCatalyst)
        self.becomeFirstResponder();
        let theMenu = UIMenuController.shared;
        let cutMenuItem = UIMenuItem(title: NSLocalizedString("Cut", comment: "Cut"), action: #selector(self.cutMenuAction(_:)));
        let copyMenuItem = UIMenuItem(title: NSLocalizedString("Copy", comment: "Copy"), action: #selector(self.copyMenuAction(_:)));
        let deleteMenuItem = UIMenuItem(title: NSLocalizedString("Delete", comment: "Delete"), action: #selector(self.deleteMenuAction(_:)));
        let lockMenuItem = UIMenuItem(title: NSLocalizedString("Lock", comment: "Lock"), action: #selector(self.lockMenuAction(_:)));
        let colorMenuItem = UIMenuItem(title: NSLocalizedString("Color", comment: "Color"), action: #selector(self.colorMenuAction(_:)));

        let options = [cutMenuItem, copyMenuItem, deleteMenuItem, lockMenuItem, colorMenuItem]
        theMenu.menuItems = options;
        theMenu.showMenu(from: self.view, rect: rect)
        #endif
    }
    
    @objc func cutMenuAction(_ sender:Any?) {
        copyAnnotation()
        self.delegate?.annotationControllerDidRemoveAnnotation(self, annotation: self.annotation)
        track("activeshape_cut_tapped", screenName: FTScreenNames.shapes)
    }

    @objc func copyMenuAction(_ sender:Any?) {
        let previousRect = shapeAnnotation.boundingRect
        // While copying annotation we need updated rect, hence updating here
        updateBoundingRect()
        copyAnnotation()
        // updating back to previous rect so that edited annotation will be saved.
        shapeAnnotation.boundingRect = previousRect
        track("activeshape_copy_tapped", screenName: FTScreenNames.shapes)
    }

    @objc func deleteMenuAction(_ sender:Any?) {
       // When we edit->delete->undo the annotation, refresh rect is not correct, hence updating rect.
       updateBoundingRect()
       deleteAnnotation()
        track("activeshape_delete_tapped", screenName: FTScreenNames.shapes)
    }
    
    private func deleteAnnotation() {
        shouldSaveAnnotation = false
        self.delegate?.annotationControllerDidRemoveAnnotation(self, annotation: shapeAnnotation)
    }
    
    @objc func lockMenuAction(_ sender:Any?) {
        lockAnnotation()
    }
    
    @objc func colorMenuAction(_ sender:Any?) {
        if let resizableView = resizableView {
            let rackData = FTRackData(type: .shape, userActivity: self.view.window?.windowScene?.userActivity)
            let editMode = FTPenColorSegment.savedSegment(for: .shape)
            let contentSize = editMode.contentSize
            let model = FTPenShortcutViewModel(rackData: rackData)
            let hostingVc = FTPenColorEditController(viewModel: model, delegate: self)
            self.penShortcutViewModel = model
            hostingVc.ftPresentationDelegate.source = resizableView
            hostingVc.ftPresentationDelegate.sourceRect = resizableView.bounds
            hostingVc.ftPresentationDelegate.permittedArrowDirections = [UIPopoverArrowDirection.left, UIPopoverArrowDirection.right]
            self.ftPresentPopover(vcToPresent: hostingVc, contentSize: contentSize, hideNavBar: true)
        }
    }
    
    private func lockAnnotation() {
        self.annotation.isLocked = true
        endEditingAnnotation()
        self.delegate?.annotationControllerDidCancel(self)
    }
    
    private func copyAnnotation() {
        // Get the General pasteboard.
        let pasteBoard = UIPasteboard.general;
        do {
            annotation.copyMode = true;
            let annotationData = try NSKeyedArchiver.archivedData(withRootObject: annotation, requiringSecureCoding: true);
            annotation.copyMode = false
            var pbInfo: [String: Any] = [String: Any]()
            pbInfo[UIPasteboard.pdfShapeAnnotationUTI()] = annotationData
            pasteBoard.items = [pbInfo];
        }
        catch {
            FTCLSLog("Error - \(error.localizedDescription)")
        }
    }
}
#if targetEnvironment(macCatalyst)
extension FTShapeAnnotationController {
    func canPerformAction(_ selector: Selector) -> Bool {
        if [#selector(self.copy(_:)),
            #selector(self.cut(_:)),
            #selector(self.delete(_:))
        ].contains(selector) {
            return true;
        }
        return false;
    }
    
    func performAction(_ selector: Selector) {
        if #selector(self.copy(_:)) == selector {
            self.copyMenuAction(nil)
        }
        else if #selector(self.cut(_:)) == selector {
            self.cutMenuAction(nil);
        }
        else if #selector(self.delete(_:)) == selector {
            self.deleteMenuAction(nil)
        }
    }
}
#endif

extension FTShapeAnnotationController: FTFavoriteColorNotifier {
    func didSelectColorFromEditScreen(_ penset: FTPenSetProtocol) {
        (self.annotation.associatedPage as? FTPageUndoManagement)?.update(annotations: [shapeAnnotation], color: UIColor(hexString: penset.color))
        publishChanges(nil)
    }
}

extension FTShapeAnnotationController: FTColorEyeDropperPickerDelegate {
    func colorPicker(picker: FTColorEyeDropperPickerController,didPickColor color:UIColor) {
        (self.annotation.associatedPage as? FTPageUndoManagement)?.update(annotations: [shapeAnnotation], color: color)
        publishChanges(nil)
        if let shortcutVm = self.penShortcutViewModel {
            if let editIndex = shortcutVm.presetEditIndex {
                shortcutVm.updatePresetColor(hex: color.hexString, index: editIndex)
                NotificationCenter.default.post(name: .PresetColorUpdate, object: nil, userInfo: ["type": FTColorToastType.edit.rawValue])
            }
            shortcutVm.updateCurrentColors()
        }
        self.penShortcutViewModel = nil
    }
}
