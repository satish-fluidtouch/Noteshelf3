//
//  FTShelfBaseHostingController_MacExtension.swift
//  Noteshelf3
//
//  Created by Narayana on 06/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

#if targetEnvironment(macCatalyst)
extension FTShelfBaseHostingController: FTToolbarActionDelegate, FTSearchToolbarActionDelegate {
    func toolbar(_ toolbar: NSToolbar, canPerformAction item: NSToolbarItem) -> Bool {
        if self.shelfViewModel.collection.isTrash, (item.itemIdentifier == FTShelfEmptyTrashToolbarItem.identifier || item.itemIdentifier == FTSelectToolbarItem.identifier) {
            return !self.shelfViewModel.shelfItems.isEmpty
        } else if item.itemIdentifier == FTShelfAddToolbarItem.identifier {
            return (shelfViewModel.collection.collectionType == .default
                    || shelfViewModel.collection.collectionType == .allNotes)
        }
        return false
    }
    
    func toolbarDidBeginSearch(_ toolbarId: NSToolbar.Identifier, textField: UISearchTextField) {
        if let splitVc = self.splitViewController as? FTShelfSplitViewController, !splitVc.checkIfGlobalSearchControllerExists() {
            splitVc.navigateToGlobalSearch()
            self.delegate = splitVc.globalSearchController
            runInMainThread(0.1) {
                self.delegate?.textFieldDidBeginEditing(textField: textField)
            }
        }
    }

    func didTextEndEditing(_ toolbarId: NSToolbar.Identifier, textField: UISearchTextField) {
        self.delegate?.textFieldDidEndEditing(textField: textField)
    }

    func didChangeText(_ toolbarId: NSToolbar.Identifier, textField: UISearchTextField) {
        self.delegate?.textFieldDidChangeSelection(textField: textField)
    }

    func didTapSearchClear(_ toolbarId: NSToolbar.Identifier, textField: UISearchTextField) {
        textField.text = ""
        runInMainThread(0.1) {
            textField.resignFirstResponder()
            self.delegate?.textFieldDidTapClearButton(textField: textField)
        }
    }

    func didTapOnSuggestion(_ toolbarId: NSToolbar.Identifier, suggestionItem: FTSuggestedItem, textField: UISearchTextField) {
        // TODO: Narayana - will be un commented once focus issue in mac is resolved
//        self.delegate?.didTapOnSuggestion(suggestionItem, textField: textField)
    }

    func toolbar(_ toolbar: NSToolbar, didTapOnMenuitem menuItem: UIAction.Identifier?) {
        guard let menuIdentifier = menuItem else {
            return
        }
        switch menuIdentifier {
        case FTShelfDisplayStyle.Gallery.menuIdentifier:
            self.shelfViewModel.displayStlye = FTShelfDisplayStyle.Gallery
        case FTShelfDisplayStyle.Icon.menuIdentifier:
            self.shelfViewModel.displayStlye = FTShelfDisplayStyle.Icon
        case FTShelfDisplayStyle.List.menuIdentifier:
            self.shelfViewModel.displayStlye = FTShelfDisplayStyle.List
        case FTShelfSortOrder.byLastOpenedDate.menuIdentifier:
            self.shelfViewModel.sortOption = FTShelfSortOrder.byLastOpenedDate
        case FTShelfSortOrder.byModifiedDate.menuIdentifier:
            self.shelfViewModel.sortOption = FTShelfSortOrder.byModifiedDate
        case FTShelfSortOrder.byName.menuIdentifier:
            self.shelfViewModel.sortOption = FTShelfSortOrder.byName
        case FTShelfSortOrder.manual.menuIdentifier:
            self.shelfViewModel.sortOption = FTShelfSortOrder.manual
        case FTHomeNavItemFilteredItemsModel.settings.menuIdenfier:
            self.shelfViewModel.delegate?.showSettings()
        case FTHomeNavItemFilteredItemsModel.selectNotes.menuIdenfier:
            if !self.shelfViewModel.shelfItems.isEmpty {
                (toolbar as? FTShelfToolbar)?.switchMode(.selectNotes)
                self.shelfViewModel.mode = .selection
                self.observeSelectModeChanges(of: toolbar)
            }
        default:
            break
        }
    }

    func toolbar(_ toolbar: NSToolbar, toolbarItem item: NSToolbarItem) {
        if item.itemIdentifier == FTShelfAddToolbarItem.identifier {
            self.showPlusOption(toolbarItem: item)
        } else if item.itemIdentifier == FTShelfToogleSidebarToolbarItem.identifier {
            if let splitvc = self.splitViewController {
                if(splitvc.displayMode == .secondaryOnly) {
                    self.splitViewController?.show(.primary)
                }
                else {
                    self.splitViewController?.hide(.primary)
                }
            }
        } else if item.itemIdentifier == FTShelfBackToolbarItem.identifier {
            (self.splitViewController as? FTShelfSplitViewController)?.hideGroup(animate: true, onCompletion: nil);
        } else if item.itemIdentifier == FTShelfEmptyTrashToolbarItem.identifier {
            self.shelfViewModel.emptyTrash();
        } else if item.itemIdentifier == FTSelectNotesToolbarItem.identifier {
            if item is FTSelectNotesToolbarItem {
                if self.shelfViewModel.areAllItemsSelected {
                    self.shelfViewModel.deselectAllItems()
                } else {
                    self.shelfViewModel.selectAllItems()
                }
            }
        } else if item.itemIdentifier == FTSelectDoneToolbarItem.identifier {
            self.shelfViewModel.mode = .normal
        } else if item.itemIdentifier == FTSelectToolbarItem.identifier {
           if !self.shelfViewModel.shelfItems.isEmpty {
               self.shelfViewModel.mode = .selection
               (toolbar as? FTShelfToolbar)?.switchMode(.selectNotes)
               self.observeSelectModeChanges(of: toolbar)
            }
        }
    }

    private func observeSelectModeChanges(of toolbar: NSToolbar) {
        self.shelfViewModel.objectWillChange
            .receive(on: DispatchQueue.main) // Receive the changes on the main thread
            .sink { [weak self] _ in
                guard let self = self else { return }
                if let shelfToolBar = toolbar as? FTShelfToolbar, let selectNotesItem = shelfToolBar.items.first(where: { $0.itemIdentifier == FTSelectNotesToolbarItem.identifier }) as? FTSelectNotesToolbarItem {
                    if self.shelfViewModel.areAllItemsSelected {
                        selectNotesItem.title = "shelf.navBar.selectNone".localized
                    } else {
                        selectNotesItem.title = "shelf.navBar.selectAll".localized
                    }
                    if self.shelfViewModel.mode == .normal {
                        self.shelfViewModel.finalizeShelfItemsEdit()
                        if self.shelfViewModel.collection.isTrash {
                            (toolbar as? FTShelfToolbar)?.switchMode(.trash)
                        } else {
                            (toolbar as? FTShelfToolbar)?.switchMode(.shelf)
                        }
                    }
                }
            }
            .store(in: &selectNoteCancellable)
    }

    private func showPlusOption(toolbarItem: NSToolbarItem) {
        let shelfNewNoteViewModel =  FTNewNotePopoverViewModel()
        shelfNewNoteViewModel.delegate = shelfViewModel
        let controller = FTShelfNewNoteController(viewModel: shelfNewNoteViewModel
                                                  , popOverHeight: 384
                                                  , appState:AppState(sizeClass: .regular)
                                                  , shelfViewModel: shelfViewModel
                                                  ,delegate: shelfViewModel.delegate as? FTShelfNewNoteDelegate)
        controller.modalPresentationStyle = .popover
        controller.popoverPresentationController?.sourceItem = toolbarItem
        self.present(controller, animated: true)
    }
}

extension FTShelfBaseHostingController {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if(action == #selector(FTMenuActionResponder.viewAsGallery(_:))
           || action == #selector(FTMenuActionResponder.viewAsIcon(_:))
           || action == #selector(FTMenuActionResponder.viewAsList(_:))
           || action == #selector(FTMenuActionResponder.sortByName(_:))
           || action == #selector(FTMenuActionResponder.sortByManual(_:))
           || action == #selector(FTMenuActionResponder.sortByLastOpenedDate(_:))
           || action == #selector(FTMenuActionResponder.sortByModifiedDate(_:))
        ) {
            return true;
        }
        else if(
            action == #selector(FTMenuActionResponder.createNewNotebook(_:))
        || action == #selector(FTMenuActionResponder.quickCreate(_:))
        ) {
            return (shelfViewModel.collection.collectionType == .default
                    || shelfViewModel.collection.collectionType == .allNotes)
        }
        return super.canPerformAction(action, withSender: sender);
    }
    
    @objc func createNewNotebook(_ sender: AnyObject?) {
        shelfViewModel.showNewNotebookPopover();
    }
    
    @objc func quickCreate(_ sender: AnyObject?) {
        shelfViewModel.quickCreateNewNotebook();
    }

    override func validate(_ command: UICommand) {
        super.validate(command);
        command.state = .off;
        switch command.action {
        case #selector(FTMenuActionResponder.viewAsIcon(_:)) :
            if(shelfViewModel.displayStlye == .Icon) {
                command.state = .on;
            }
        case #selector(FTMenuActionResponder.viewAsList(_:)) :
            if(shelfViewModel.displayStlye == .List) {
                command.state = .on;
            }
        case #selector(FTMenuActionResponder.viewAsGallery(_:)) :
            if(shelfViewModel.displayStlye == .Gallery) {
                command.state = .on;
            }
        case #selector(FTMenuActionResponder.sortByName(_:)) :
            if(shelfViewModel.sortOption == .byName) {
                command.state = .on;
            }
        case #selector(FTMenuActionResponder.sortByManual(_:)) :
            if(shelfViewModel.sortOption == .manual) {
                command.state = .on;
            }
        case #selector(FTMenuActionResponder.sortByModifiedDate(_:)) :
            if(shelfViewModel.sortOption == .byModifiedDate) {
                command.state = .on;
            }
        case #selector(FTMenuActionResponder.sortByCreatedDate(_:)) :
            if(shelfViewModel.sortOption == .byCreatedDate) {
                command.state = .on;
            }
        case #selector(FTMenuActionResponder.sortByLastOpenedDate(_:)) :
            if(shelfViewModel.sortOption == .byLastOpenedDate) {
                command.state = .on;
            }
        default:
            break;
        }
    }
}

extension FTShelfBaseHostingController: FTMenuActionResponder {
    func viewAsIcon(_ sender: AnyObject?) {
        shelfViewModel.displayStlye = .Icon
    }
    
    func viewAsGallery(_ sender: AnyObject?) {
        shelfViewModel.displayStlye = .Gallery
    }
    
    func viewAsList(_ sender: AnyObject?) {
        shelfViewModel.displayStlye = .List
    }
    
    func sortByName(_ sender: AnyObject?) {
        shelfViewModel.sortOption = .byName;
    }
    
    func sortByManual(_ sender: AnyObject?) {
        shelfViewModel.sortOption = .manual;
    }
    
    func sortByModifiedDate(_ sender: AnyObject?) {
        shelfViewModel.sortOption = .byModifiedDate;
    }
    
    func sortByLastOpenedDate(_ sender: AnyObject?) {
        shelfViewModel.sortOption = .byLastOpenedDate;
    }
}
#endif
