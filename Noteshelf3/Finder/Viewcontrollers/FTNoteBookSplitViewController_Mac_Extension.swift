//
//  FTNoteBookSplitViewController_Mac_Extension.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 03/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

#if targetEnvironment(macCatalyst)
extension FTNoteBookSplitViewController {
    func configureMacToolbar() {
        if let toolbar = self.nsToolbar as? FTNotebookToolbar {
            toolbar.toolbarActionDelegate = self;
            toolbar.undoManager = self.documentViewController?.documentViewController.undoManager;
        }
        else {
            if let windowScene = self.view.uiWindowScene {
                let toolbar = FTNotebookToolbar(windowScene: windowScene);
                toolbar.undoManager = self.documentViewController?.documentViewController.undoManager;
                toolbar.toolbarActionDelegate = self;
                self.titlebar?.toolbar = toolbar;
            }
        }
    }
}

extension FTNoteBookSplitViewController: FTToolbarActionDelegate {
    func toolbarCurrentDeskMode(_ toolbar: NSToolbar) -> RKDeskMode {
        return self.documentViewController?.documentViewController.currentDeskMode ?? .deskModeView;
    }
    
    func toolbar(_ toolbar: NSToolbar, canPerformAction item: NSToolbarItem) -> Bool
    {
        return true;
    }

    func toolbar(_ toolbar: NSToolbar, toolbarItem item: NSToolbarItem) {
        guard let pdfController = self.documentViewController?.documentViewController else {
            return;
        }
        if let noteToolbat = item as? FTNotebookToolsToolbarItem {
            pdfController.didTapCenterToolButton(noteToolbat.deskToolType, toolbarItem: item);
        }
        else {
            switch(item.itemIdentifier) {
            case FTNotebookToolbarItemType.back.toolbarIdentifier:
                pdfController.backButtonAction(with: item)
            case FTNotebookToolbarItemType.undo.toolbarIdentifier:
                pdfController.undoButtonAction();
            case FTNotebookToolbarItemType.redo.toolbarIdentifier:
                pdfController.redoButtonAction();
            case FTNotebookToolbarItemType.share.toolbarIdentifier:
                pdfController.showShareOptions(with: item);
            case FTNotebookToolbarItemType.add.toolbarIdentifier:
                pdfController.addAnnotationButtonAction(toolbarItem: item)
            case FTNotebookToolbarItemType.more.toolbarIdentifier:
                // To fix the issue of popover dismissal tap leads to represent issue in MAC
                if let presentedViewController = self.presentedViewController as? UINavigationController {
                    if let childViewController = presentedViewController.viewControllers.first, childViewController is FTNotebookMoreOptionsViewController {
                        return
                    }
                }
                pdfController.settingsButtonAction()
            default:
                break;
            }
        }
    }
    
    func toolbar(_ toolbar: NSToolbar, didTapOnMenuitem menuItem: UIAction.Identifier?) {
        guard let pdfController = self.documentViewController?.documentViewController else {
            return;
        }
        pdfController.toolbar(toolbar,didTapOnMenuitem:menuItem)
    }
}
#endif
