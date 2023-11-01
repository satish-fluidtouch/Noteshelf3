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
        var status = false
        if self.isInTrash(), (item.itemIdentifier == FTShelfEmptyTrashToolbarItem.identifier || item.itemIdentifier == FTSelectToolbarItem.identifier) {
            status = !self.shelfViewModel.shelfItems.isEmpty && !self.isInSearchMode()
        } else if item.itemIdentifier == FTShelfAddToolbarItem.identifier {
            status = self.toEnableAddToolbarItem()
        } else if item.itemIdentifier == FTShelfMoreToolbarItem.identifier {
            status = self.toEnableMoreToolbarItem()
        }
        return status
    }

    private func toEnableMoreToolbarItem() -> Bool {
        let status = (shelfViewModel.collection.collectionType == .default
                      || shelfViewModel.collection.collectionType == .allNotes || shelfViewModel.collection.collectionType == .starred) && !self.isInSearchMode()
        return status
    }

    private func toEnableAddToolbarItem() -> Bool {
        var status = false
        if !(shelfViewModel.collection.collectionType == .starred) {
            status = (shelfViewModel.collection.collectionType == .default
                      || shelfViewModel.collection.collectionType == .allNotes) && !self.isInSearchMode()
        }
        return status
    }

    func toolbarDidBeginSearch(_ toolbarId: NSToolbar.Identifier, textField: UISearchTextField) {
        if let splitVc = self.splitViewController as? FTShelfSplitViewController, !self.isInSearchMode() {
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
        // Some times - view may not be ready during second level searches inside groups, or followed by results
        // Fixed with globalSearchVc.isViewLoaded
        if let globalSearchVc = self.delegate as? FTGlobalSearchController, globalSearchVc.isViewLoaded {
            self.delegate?.textFieldDidChangeSelection(textField: textField)
        }
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
                if let shelfToolbar = toolbar as? FTShelfToolbar {
                    shelfToolbar.switchMode(.selectNotes)
                    self.shelfViewModel.mode = .selection
                    self.observeShelfModelChanges(of: shelfToolbar)
                }
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
               if let shelfToolbar = toolbar as? FTShelfToolbar {
                   shelfToolbar.switchMode(.selectNotes)
                   self.observeShelfModelChanges(of: shelfToolbar)
               }
            }
        }
    }

    internal func observeShelfModelChanges(of toolbar: FTShelfToolbar) {
   // TODO: Refactor needed - Shelf items to be observed - Narayana
        self.shelfViewModel.objectWillChange
            .receive(on: DispatchQueue.main) // Receive the changes on the main thread
            .sink { [weak self] _ in
                guard let self = self else { return }
                if let selectNotesItem = toolbar.getToolbarItem(with: FTSelectNotesToolbarItem.identifier) as? FTSelectNotesToolbarItem {
                    if self.shelfViewModel.areAllItemsSelected {
                        selectNotesItem.title = "shelf.navBar.selectNone".localized
                    } else {
                        selectNotesItem.title = "shelf.navBar.selectAll".localized
                    }
                    if self.shelfViewModel.mode == .normal {
                        self.shelfViewModel.finalizeShelfItemsEdit()
                        if self.isInTrash() {
                            toolbar.switchMode(.trash)
                        } else {
                            toolbar.switchMode(.shelf)
                            toolbar.showBackButton(toShowBackButton())
                        }
                    }
                } else if self.isInTrash() {
                    if let emptyTrashitem = toolbar.getToolbarItem(with: FTShelfEmptyTrashToolbarItem.identifier) as? FTShelfEmptyTrashToolbarItem {
                        emptyTrashitem.validate()
                    }
                    if let selectItem = toolbar.getToolbarItem(with: FTSelectToolbarItem.identifier) as? FTSelectToolbarItem {
                        selectItem.validate()
                    }
                }
            }
            .store(in: &selectNoteCancellable)
    }

    private func toShowBackButton() -> Bool {
        var status = false
        if let _ = self.shelfViewModel.groupItem {
            status = true
        } else if let navVc = self.navigationController, self.shelfViewModel.collection.isAllNotesShelfItemCollection, navVc.children.last is FTShelfViewControllerNew { // When in Home notes(while seeing all notes at once) - when in pushed
            status = true
        }
        return status
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

// MARK: Helper functions
extension FTShelfBaseHostingController {
    private func isInSearchMode() -> Bool {
        var status = false
        if let splitVc = self.splitViewController as? FTShelfSplitViewController, splitVc.checkIfGlobalSearchControllerExists() {
            status = true
        }
        return status
    }

    private func isInTrash() -> Bool {
        let status = self.shelfViewModel.collection.isTrash
        return status
    }
}
#endif
