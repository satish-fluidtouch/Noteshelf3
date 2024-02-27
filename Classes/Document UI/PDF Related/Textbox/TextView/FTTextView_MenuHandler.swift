//
//  FTTextView_MenuHandler.swift
//  Noteshelf3
//
//  Created by Narayana on 13/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension FTTextView {
    override func canPerformAction(_ action: Selector, withSender sender: Any!) -> Bool {
        if let controller = self.annotationViewController,  controller.isEditMode {
            if [#selector(self.copy(_:)),
                #selector(self.cut(_:)),
                #selector(self.paste(_:)),
                #selector(self.select(_:)),
                #selector(self.selectAll(_:))
            ].contains(action) {
                return super.canPerformAction(action, withSender: sender);
            }

            if action == #selector(self.colorMenuItemAction(_:)) {
                return true;
            }

            if self.isTextHighLighted() {
                if [#selector(self.lookUpMenuItemAction(_:)), #selector(self.shareMenuItemAction(_:)),
                    #selector(self.delete(_:))].contains(action) {
                    return true
                } else if self.checkIfToShowEditLinkOptions() {
                    if [#selector(self.editLinkMenuItemAction(_:)), #selector(self.removeLinkMenuItemAction(_:))].contains(action) {
                        return true
                    }
                } else if [#selector(self.linkMenuItemAction(_:))].contains(action) {
                    return true
                }
            }
        }

        if action == Selector(("replace:")) {
            return true
        }
        return false
    }

    override func editMenu(for textRange: UITextRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        var actions = suggestedActions
        let menu = self.getRequiredMenu()
        actions.append(menu)
        return UIMenu(children: actions)
    }

    func getRequiredMenu() -> UIMenu {
        var menuItems = [UIMenuElement]()
        if self.isTextHighLighted() {
#if !targetEnvironment(macCatalyst)
            let colorAction = UIAction(title: "Color".localized) { action in
                self.colorMenuItemAction(action)
            }
            let lookUpAction = UIAction(title: "LookUp".localized) { action in
                self.lookUpMenuItemAction(action)
            }
            let shareAction = UIAction(title: "Share".localized) { action in
                self.shareMenuItemAction(action)
            }
            menuItems.append(contentsOf: [colorAction, lookUpAction, shareAction])
#endif
            if self.checkIfToShowEditLinkOptions() {
                let editLinkAction = UIAction(title: "textLink_editLink".localized) { action in
                    self.editLinkMenuItemAction(action)
                }
                let deleteLinkAction = UIAction(title: "textLink_removeLink".localized) { action in
                    self.removeLinkMenuItemAction(action)
                }
                menuItems.append(contentsOf: [editLinkAction, deleteLinkAction])
            } else {
                let linkAction = UIAction(title: "textLink_linkTo".localized) { action in
                    self.linkMenuItemAction(action)
                }
                menuItems.append(contentsOf: [linkAction])
            }
        } else {
#if !targetEnvironment(macCatalyst)
            let colorAction = UIAction(title: "Color".localized) { action in
                self.colorMenuItemAction(action)
            }
            menuItems.append(contentsOf: [colorAction])
#endif
        }
        let menu = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: menuItems)
        return menu
    }
}

extension FTTextView {
    @objc func linkMenuItemAction(_ sender: Any?) {
        if let controller = self.annotationViewController {
            controller.performLinkAction(sender)
            if controller.isEditMode {
                FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.selectedTextLinkToTap)
            } else {
                FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.linkToTap)
            }
        }
    }

    @objc func editLinkMenuItemAction(_ sender: Any?) {
        if let controller = self.annotationViewController {
            controller.performLinkAction(sender)
            if controller.isEditMode {
                FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.selectedTextEditLinkTap)
            } else {
                FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.editLinkTap)
            }
        }
    }

    @objc func removeLinkMenuItemAction(_ sender: Any?) {
        if let controller = self.annotationViewController {
            controller.removeLinkAction(sender)
            if controller.isEditMode {
                FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.selectedTextRemoveLinkTap)
            } else {
                FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.removeLinkTap)
            }
        }
    }

    @objc func lookUpMenuItemAction(_ sender: Any?) {
        if let controller = self.annotationViewController {
            controller.performLookUpMenu(sender)
        }
    }

    @objc func shareMenuItemAction(_ sender: Any?) {
        if let controller = self.annotationViewController {
            controller.performShareMenu(sender)
        }
    }

    @objc func colorMenuItemAction(_ sender: Any?) {
        if let controller = self.annotationViewController {
            controller.performColorMenu(sender)
        }
    }

    func getSelectedText() -> String? {
        if let selectedTextRange: UITextRange = self.selectedTextRange,!selectedTextRange.isEmpty {
            return self.text(in: selectedTextRange);
        }
        return nil
    }

    func isTextHighLighted() -> Bool {
        return !(self.selectedTextRange?.isEmpty ?? true);
    }

    func checkIfToShowEditLinkOptions() -> Bool {
        var shouldShowEditLinkOptions = false
        if isTextHighLighted(),self.selectedRange.length > 0 {
            let startingLocation = self.selectedRange.location
            let endingLocation = startingLocation + self.selectedRange.length
            shouldShowEditLinkOptions = checkLinkConsistencyInRange(startingLocation..<endingLocation)
        } else if self.attributedText.length > 0 {
            if let textAnnotVc = self.annotationViewController, !textAnnotVc.isEditMode {
                let trimmedRange = self.trimWhitespaceAndNewlines(from: 0..<self.attributedText.length, in: self.attributedText)
                shouldShowEditLinkOptions = checkLinkConsistencyInRange(trimmedRange)
            }
        }
        return shouldShowEditLinkOptions
    }

    private func trimWhitespaceAndNewlines(from range: Range<Int>, in attributedText: NSAttributedString) -> Range<Int> {
        var trimmedRange = range
        // Trim leading whitespaces, newlines, and tabs
        while trimmedRange.count > 0 {
            let nsRange = NSRange(location: trimmedRange.lowerBound, length: 1)
            let substring = attributedText.attributedSubstring(from: nsRange).string
            if let firstScalar = substring.unicodeScalars.first, CharacterSet.whitespacesAndNewlines.contains(firstScalar) || substring == "\t" {
                trimmedRange = trimmedRange.dropFirst()
            } else {
                break
            }
        }
        // Trim trailing whitespaces, newlines, and tabs
        while trimmedRange.count > 0 {
            let nsRange = NSRange(location: trimmedRange.upperBound - 1, length: 1)
            let substring = attributedText.attributedSubstring(from: nsRange).string
            if let firstScalar = substring.unicodeScalars.first, CharacterSet.whitespacesAndNewlines.contains(firstScalar) || substring == "\t" {
                trimmedRange = trimmedRange.dropLast()
            } else {
                break
            }
        }
        return trimmedRange
    }

    private func checkLinkConsistencyInRange(_ range: Range<Int>) -> Bool {
        var firstSchemeUrl: URL?
        for location in range {
            let charAttrs = self.attributedText.attributes(at: location, effectiveRange: nil)
            if let charSchemeUrl = charAttrs[.link] as? URL {
                if firstSchemeUrl == nil {
                    firstSchemeUrl = charSchemeUrl
                } else if charSchemeUrl != firstSchemeUrl {
                    return false
                }
            } else {
                return false
            }
        }
        return firstSchemeUrl != nil
    }
}
