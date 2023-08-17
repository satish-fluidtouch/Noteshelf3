//
//  FTShelfCategoryViewController_iOS13.swift
//  Noteshelf
//
//  Created by Amar on 07/01/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Intents
import FTStyles

private let ShelfCategoryHeaderViewIdentifier_iOS = "ShelfCategoryHeaderViewIdentifier_iOS"
let kNotebookUnpinNotification = "kNotebookUnpinNotification"

class FTShelfCategoryViewController_iOS13: FTShelfCategoryViewController {
    //******************************
    var isResizing: Bool = false
    var isObserversAdded: Bool = false
    var selectedIndexPath: IndexPath = IndexPath(row: 0, section: 0)
    
    @IBOutlet weak var sideMenuBtn: FTThemeableButton!

    @IBOutlet weak var closeButton: UIButton?
    var horizontalTransitioningDelegate: FTHorizontalTransitionDelegate = FTHorizontalTransitionDelegate(with: FTHorizontalPresentationStyle.interaction, direction: .leftToRight, supportsFullScreen: false)

    func didChangeState(to screenState: FTHotizontalScreenState) {
        
    }
    
    func shouldStartWithFullScreen() -> Bool {
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigation(hideBackButton: true, title: "Noteshelf")
    }
    //******************************
    override func viewDidLoad() {
        let nib = UINib.init(nibName: "FTiOSShelfCategoryHeaderView", bundle: nil);
        self.tableView?.register(nib, forHeaderFooterViewReuseIdentifier: ShelfCategoryHeaderViewIdentifier_iOS);
        super.viewDidLoad()
        if (self.displayMode == .notebook) {
            self.closeButton?.isHidden = false
            self.optionsButton?.isHidden = true
        }
        if(UIDevice.current.isIphone()) {
            self.blurView?.isHidden = false
            self.tableView?.layer.shadowOpacity = 0.1;
            self.tableView?.layer.shadowColor = UIColor.headerColor.cgColor;
            self.tableView?.layer.shadowRadius = 20;
            self.tableView?.layer.shadowOffset = CGSize(width: 0, height: 4);
            addTapGesture()
        }
        self.addCollapseObservers()
        self.tableView?.dragInteractionEnabled = true
        self.tableView?.dragDelegate = self
//        self.tableView?.automaticallyAdjustsScrollIndicatorInsets = fa
    }
    
    override func removeObserversIfNeeded() {
        if self.isObserversAdded {
            self.isObserversAdded = false
            UserDefaults.standard.removeObserver(self, forKeyPath: "collapsed_category_\(FTShelfCategoryType.user)")
            UserDefaults.standard.removeObserver(self, forKeyPath: "collapsed_category_\(FTShelfCategoryType.starred)")
            UserDefaults.standard.removeObserver(self, forKeyPath: "collapsed_category_\(FTShelfCategoryType.recent)")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            NotificationCenter.default.post(name: NSNotification.Name.FTShelfThemeDidChange, object: nil);
        }
    }

    func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.blurView?.addGestureRecognizer(tap)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let category = shelfCollections[section]
        if(self.shelfCollections[section].items.isEmpty || category.type == .systemDefault) {
            return 20;
        }
        return 34;
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 24;
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.displayMode == .notebook {
            let categorySection = self.shelfCollections[indexPath.section]
            if indexPath.row < categorySection.items.count {
                let item = categorySection.items[indexPath.row] as? FTShelfItemCollection
                if categorySection.type == .user, let category = item, category.isTrash {
                    return 0.0
                }
            }
        }
        let category = self.shelfCollections[indexPath.section];
        if category.type == .recent {
            return 64
        }
        if(category.type == FTShelfCategoryType.user) {
            if category.items.count == indexPath.row {
                return 44
            }
        }
        return 44;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //        self.editShelfItemCollection(nil)
//        if let navVc = self.splitViewController?.viewControllers.last as? UINavigationController {
//            if let shelfController = navVc.children.first as? FTShelfViewController {
//                shelfController.view.alpha = 1.0
//                shelfController.view.transform = CGAffineTransform.identity
//            }
//        }
        self.selectedIndexPath = indexPath
        //Start spinner animation,while opening book
            let category = self.shelfCollections[indexPath.section];
            if category.type == .recent || category.type == .starred{
                if let documentItem = category.items[indexPath.row] as? FTDocumentItemProtocol {
                    if documentItem.isDownloaded, let cell = tableView.cellForRow(at: indexPath) as? FTShelfCategoryRecentEntryTableViewCell {
                        cell.bookOpenSpinner?.startRotating()
                    }
                    self.delegate?.shelfCategory(self, didSelectShelfItem: documentItem, inCollection: nil)
                }
            }
            else {
                super.tableView(tableView, didSelectRowAt: indexPath)
                #if !targetEnvironment(macCatalyst)
                //To hide the side panel when closing a book while the split mode is primaryOverlay
                if UIDevice.current.isIphone() {
                    self.delegate?.hideCategoriesPanel()
                }
//                else if let baseVC = self.splitViewController?.parent as? FTBaseShelfiOS13ViewController {
//                    if let categoryVC = baseVC.shelfCategoryVC as? FTShelfCategoryViewController_iOS13, let splitVC = categoryVC.splitViewController {
//                        UIView.animate(withDuration: 0.2) {
//                            if splitVC.displayMode == .primaryOverlay {
//                                splitVC.preferredDisplayMode = .primaryHidden
//                            }
//                        }
//                    }
//                }
                #endif
            }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let category = self.shelfCollections[section];
        if category.type == .systemDefault {
            let view = UIView()
            view.backgroundColor = .clear
            return view
        } else if !category.items.isEmpty,
            let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ShelfCategoryHeaderViewIdentifier_iOS) as? FTiOSShelfCategoryHeaderView {
            headerView.headerDelegate = self;
            headerView.configUI(category);
            return headerView;
        }
        return nil;
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        //when the menu is actually invoked
        self.editShelfItemCollection(nil);
        
        var contextMenu : UIContextMenuConfiguration?;
        let identifier = indexPath as NSIndexPath
        let category = self.shelfCollections[indexPath.section];
        if self.displayMode == .notebook && category.type == .user {
            return nil
        }

        switch category.type {
        case .user:
            track("Shelf_QuickAccess_LongPressCategory", params: [:],screenName: FTScreenNames.shelfQuickAccess)
            let categories = self.shelfCollections[indexPath.section].items;
            
            if indexPath.row >= categories.count { // = is for add new category section
                return nil
            }
            
            guard let eachCollection = categories[indexPath.row] as? FTShelfItemCollection else {
                return nil;
            };
            
            if((eachCollection.collectionType == .recent) || (eachCollection.collectionType == .allNotes)){
                return nil;
            }
            
            let actionProvider : ([UIMenuElement]) -> UIMenu? = { _ in
                var actions = [UIMenuElement]()
                if eachCollection.isTrash {
                    let trashAction = UIAction(title: NSLocalizedString("EmptyTrash", comment: "Empty Trash")) { [weak self] _ in
                        self?.emptyTrash(eachCollection)
                        track("Shelf_Trash_EmptyTrash", params: [:],screenName: FTScreenNames.shelfQuickAccess)
                    }
                    trashAction.attributes = .destructive;
                    actions.append(trashAction)
                }else{
                    let canRename: Bool = !eachCollection.isUnfiledNotesShelfItemCollection
                    if canRename {
                        let renameAction = UIAction(title: NSLocalizedString("Rename", comment: "Rename")) { [weak self] _ in
                            track("Shelf_QuickAccess_LongPCategory_Edit", params: [:],screenName: FTScreenNames.shelfQuickAccess)
                            self?.editShelfItemCollection(eachCollection,indexPath:indexPath);
                        }
                        actions.append(renameAction)
                    }
                    let deleteAction = UIAction(title: NSLocalizedString("MoveToTrash", comment: "Move To Trash")) { [weak self] _ in
                        track("Shelf_QuickAccess_LongPCategory_ToTrash", params: [:],screenName: FTScreenNames.shelfQuickAccess)
                        self?.deleteShelfItemCollection(eachCollection);
                    }
                    deleteAction.attributes = .destructive;
                    actions.append(deleteAction)
                }
                //Return menu with actions
                return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: actions)
            }
            contextMenu = UIContextMenuConfiguration(identifier: identifier, previewProvider: nil, actionProvider: actionProvider)
        case .recent:
            track("Shelf_QuickAccess_LongPressRecent", params: [:],screenName: FTScreenNames.shelfQuickAccess)
            guard let item = category.items[indexPath.row] as? FTShelfItemProtocol else {
                return nil;
            };
            let actionProvider : ([UIMenuElement]) -> UIMenu? = { _ in
                var actions = [UIMenuElement]()

                let openInWindowAction = UIAction(title: NSLocalizedString("OpenInNewWindow", comment: "Open in New Window")) {[weak self] _ in
                    self?.openItemInNewWindow(item,pageIndex: nil)
                }
                if !(UIDevice.current.isIphone()) {
                    actions.append(openInWindowAction)
                }

                let pinAction = UIAction(title: NSLocalizedString("PinNotebook", comment: "Pin Notebook")) { [weak self] _ in
                    track("Shelf_QuickAccess_LongPRecent_Pin", params: [:],screenName: FTScreenNames.shelfQuickAccess)
                    self?.addShelfItemToPinCollection(item);
                }
                actions.append(pinAction)
                
//                let createSiriAction = UIAction(title: FTRecentEditMenuItem.createSiriShortcut.localizedTitle ) {[weak self] _ in
//                    var onController: UIViewController?
//                    if(UIDevice.current.isIphone()) {
//                        if let parentVC = self?.parent as? FTBaseShelfiPhoneViewController {
//                            onController = parentVC
//                        }
//                    } else {
//                        if let baseVC = self?.splitViewController?.parent as? FTBaseShelfViewController {
//                            onController = baseVC
//                        }
//                    }
//                    if onController == nil {
//                        if let baseParentVC = self?.navigationController?.topViewController {
//                            onController = baseParentVC
//                        }
//                    }
//                    track("Shelf_QuickAccess_LongPRecent_Siri", params: [:],screenName: FTScreenNames.shelfQuickAccess)
//                    FTSiriShortcutManager.shared.handleCreateSiriShortCut(for: item, onController: onController)
//                }
//                actions.append(createSiriAction)
                
                let removeFromRecent = UIAction(title: NSLocalizedString("RemoveFromRecents", comment: "Remove From Recents")) { [weak self] _ in
                    track("Shelf_QuickAccess_LongPRecent_Remove", params: [:],screenName: FTScreenNames.shelfQuickAccess)
                    self?.removeShelfItemsFromRecent([item],from:.recent);
                }
                removeFromRecent.attributes = UIMenuElement.Attributes.destructive
                actions.append(removeFromRecent)

                //Return menu with actions
                return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: actions)
            }
            contextMenu = UIContextMenuConfiguration(identifier: identifier, previewProvider: { () -> UIViewController? in
                let storyboard = UIStoryboard(name: "FTShelfItems", bundle: nil)
                let previewVC = storyboard.instantiateViewController(identifier: "FTShelfItemPreviewViewController") as? FTShelfItemPreviewViewController
                previewVC?.shelfItem = item
                return previewVC
            }, actionProvider: actionProvider)

        case .starred:
            track("Shelf_QuickAccess_LongPressPinnedNB", params: [:],screenName: FTScreenNames.shelfQuickAccess)
            guard let item = category.items[indexPath.row] as? FTShelfItemProtocol else {
                return nil;
            };
            let actionProvider : ([UIMenuElement]) -> UIMenu? = { _ in
                var menuToReturn: UIMenu?
                var actions = [UIMenuElement]()

                let openInWindowAction = UIAction(title: NSLocalizedString("OpenInNewWindow", comment: "Open in New Window")) {[weak self] _ in
                    self?.openItemInNewWindow(item,pageIndex: nil)
                }
                if !(UIDevice.current.isIphone()) {
                    actions.append(openInWindowAction)
                }

//                let createSiriAction = UIAction(title: FTRecentEditMenuItem.createSiriShortcut.localizedTitle ) { [weak self] _ in
//                    var onController: UIViewController?
//                    if(UIDevice.current.isIphone()) {
//                        if let parentVC = self?.parent as? FTBaseShelfiPhoneViewController {
//                            onController = parentVC
//                        }
//                    } else {
//                        if let baseVC = self?.splitViewController?.parent as? FTBaseShelfViewController {
//                            onController = baseVC
//                        }
//                    }
//                    if onController == nil {
//                        if let baseParentVC = self?.navigationController?.topViewController {
//                            onController = baseParentVC
//                        }
//                    }
//                    track("Shelf_QuickAccess_LongPPinnedNB_Siri", params: [:],screenName: FTScreenNames.shelfQuickAccess)
//                    FTSiriShortcutManager.shared.handleCreateSiriShortCut(for: item, onController: onController)
//                }
//                actions.append(createSiriAction)
                let unpinAction = UIAction(title: NSLocalizedString("UnpinNotebook", comment: "Un pin Notebook")) { [weak self] _ in
                    track("Shelf_QuickAccess_LongPPinnedNB_UnpinNB", params: [:],screenName: FTScreenNames.shelfQuickAccess)
                    self?.removeShelfItemsFromRecent([item],from:.favorites);
                    NotificationCenter.default.post(name: Notification.Name(rawValue: kNotebookUnpinNotification), object: nil, userInfo: ["UnpinNotebook" :  item])
                }
                unpinAction.attributes = UIMenuElement.Attributes.destructive
                actions.append(unpinAction)
                
                //Return menu with actions
                menuToReturn = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: actions)
                return menuToReturn
            }
            contextMenu = UIContextMenuConfiguration(identifier: identifier, previewProvider: { () -> UIViewController? in
                let storyboard = UIStoryboard(name: "FTShelfItems", bundle: nil)
                let previewVC = storyboard.instantiateViewController(identifier: "FTShelfItemPreviewViewController") as? FTShelfItemPreviewViewController
                previewVC?.shelfItem = item
                return previewVC
            }, actionProvider: actionProvider)

        default:
            break;
        }
        return contextMenu;
    }

    func tableView(_ tableView: UITableView, willDisplayContextMenu configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.enableCloudUpdates), object: nil)
        FTNoteshelfDocumentProvider.shared.disableCloudUpdates()
    }
    
    func tableView(_ tableView: UITableView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.enableCloudUpdates), object: nil)
        self.perform(#selector(self.enableCloudUpdates), with: nil, afterDelay: 0.5)
    }

    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if let identifier = configuration.identifier as? IndexPath {
            let category = self.shelfCollections[identifier.section];
            
            var previewCell : UITableViewCell?;
            
            if(category.type == FTShelfCategoryType.user) {
                let cell = tableView.cellForRow(at: identifier) as? FTShelfCategoryTableViewCell
                previewCell = cell
            } else {
                let cell = tableView.cellForRow(at: identifier) as? FTShelfCategoryRecentEntryTableViewCell
                previewCell = cell
            }
            
            if let cell = previewCell {
                let itemBounds = cell.contentView.bounds
                let parameters = UIPreviewParameters()
                //parameters.backgroundColor = .clear
                let preview = UITargetedPreview.init(view: cell,parameters: parameters)
                preview.parameters.visiblePath = UIBezierPath.init(roundedRect: cell.contentView.convert(itemBounds, to: previewCell), cornerRadius: 4.0)
                
                return preview
            }
        }
        return nil
    }

    
    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if let identifier = configuration.identifier as? IndexPath {
            let category = self.shelfCollections[identifier.section];
            
            var previewView : UIView!;
            
            if(category.type == FTShelfCategoryType.user) {
                let cell = tableView.cellForRow(at: identifier) as? FTShelfCategoryTableViewCell
                previewView = cell
            } else {
                let cell = tableView.cellForRow(at: identifier) as? FTShelfCategoryRecentEntryTableViewCell
                previewView = cell
            }
            
            //get target preview
            let parameters = UIPreviewParameters()
           // parameters.backgroundColor = .clear
            let targetPreview = UITargetedPreview.init(view: previewView,parameters: parameters)
            
            return targetPreview
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let category = self.shelfCollections[indexPath.section];
        if category.type == .user {
            let categories = self.shelfCollections[indexPath.section].items;
            
            if indexPath.row >= categories.count {
                return false
            }
            guard let eachCollection = categories[indexPath.row] as? FTShelfItemCollection else {
                return false;
            };
            
            if((eachCollection.collectionType == .system && !eachCollection.isTrash) ||
                eachCollection.collectionType == .recent ||
                eachCollection.collectionType == .allNotes ||
                self.displayMode == .notebook) {
                return false;
            }
        }
        
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let category = self.shelfCollections[indexPath.section];
        let items = self.shelfCollections[indexPath.section].items;
       
        if(category.type == FTShelfCategoryType.user) {
            guard let collection = items[indexPath.row] as? FTShelfItemCollection, self.displayMode == .shelf else {
                return nil;
            }
            let swipeTitle = NSLocalizedString(collection.isTrash ? "EmptyTrash" : "Trash", comment: "Trash")
            let deleteAction = UIContextualAction(style: .destructive, title: swipeTitle) { [weak self] (_, _, _) in
                guard let `self` = self else {
                    return
                }
                if collection.isTrash {
                    if collection.childrens.isEmpty {
                        tableView.reloadData()
                    }
                    else {
                        let alertController = UIAlertController(title: NSLocalizedString("EmptyTrashConfirmation", comment: "Are you sure you want to..."),
                                                                message:"",
                                                                preferredStyle: .alert);
                        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { _ in
                            tableView.reloadData()
                        });
                        alertController.addAction(cancelAction);
                        
                        let deleteAction = UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .destructive, handler: { _ in
//                            FTNoteshelfDocumentProvider.emptyTrashCollection(collection, onController: self, onCompletion: {
//                                tableView.reloadData()
//                            })
                        });
                        alertController.addAction(deleteAction);
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
                else {
                    self.deleteShelfItemCollection(collection);
                }
            }
            deleteAction.backgroundColor = UIColor.init(hexString: "CC4235")
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            return configuration
        } else {
            guard let item = category.items[indexPath.row] as? FTShelfItemProtocol else {
                return nil;
            };
            let swipeTitle = NSLocalizedString(category.type == .starred ? "Unpin" : "Pin", comment: "")
            let deleteAction = UIContextualAction(style: .normal, title: swipeTitle) { [weak self] (_, _, _) in
                if category.type == .starred {
                    self?.removeShelfItemsFromRecent([item],from:.favorites);
                } else {
                    self?.addShelfItemToPinCollection(item)
                }
            }
            deleteAction.backgroundColor = UIColor.init(hexString: category.type == .starred ? "CC4235" : "4AA1FF")
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            return configuration
        }
    }
    
    private func siriShortcutMenu(for item: FTShelfItemProtocol) -> FTRecentEditMenuItem {
        var menuItem: FTRecentEditMenuItem = .createSiriShortcut
        let semaphore = DispatchSemaphore.init(value: 0);
        DispatchQueue.global().async {[weak self] in
            guard let strongSelf = self else {
                semaphore.signal();
                return;
            }
            strongSelf.isSiriShortcutAvailable(for: item) { (voiceShortcut) in
                if let shortcut = voiceShortcut {
                    menuItem = .editSiriShortcut(voiceShortcut: shortcut)
                }
                semaphore.signal();
            }
        }
        semaphore.wait();
        return menuItem
    }
    
    private func isSiriShortcutAvailable(for item: FTShelfItemProtocol ,completion:@escaping (_ voiceShortcut: INVoiceShortcut?) -> Void) {
        if let uuid = (item as? FTDocumentItemProtocol)?.documentUUID {
            FTSiriShortcutManager.shared.getShortcutForUUID(uuid) {(_, voiceShortcut) in
                completion(voiceShortcut)
            }
        }
        else {
            completion(nil)
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
        if let path = keyPath, path.contains("collapsed_category"){
            self.handleObserver(forKeyPath: path)
        }
    }
    @objc private func enableCloudUpdates() {//Workaround for a crash while reordering a book which has Sync in progress with the iCloud
        FTNoteshelfDocumentProvider.shared.enableCloudUpdates()
    }
}

//MARK: Action Methods
extension FTShelfCategoryViewController_iOS13 {
    func configureNavigation(hideBackButton: Bool = false, title: String, preferLargeTitle: Bool = true) {
        self.navigationItem.hidesBackButton = true
        self.navigationController?.navigationItem.hidesBackButton = true
        self.navigationItem.title = title
        if isRegularClass() {
            self.navigationController?.additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        }
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.clearFaceFont(for: .medium, with: 20)]
        self.navigationController?.navigationBar.largeTitleTextAttributes = [
            NSAttributedString.Key.font: UIFont.clearFaceFont(for: .medium, with: 28)]
        self.navigationController?.navigationBar.prefersLargeTitles = preferLargeTitle
        self.navigationController?.navigationItem.largeTitleDisplayMode = .always
   }
    
    override func isRegularClass() -> Bool {
        var isRegular = super.isRegularClass()
        if let splitViewController  {
            isRegular = splitViewController.isRegularClass()
        }
        return isRegular
    }
    
    @objc func settingsBtnTapped(_ sender : UIButton) {
        settingsButtonClicked(sender)
    }
    
    @IBAction private func settingsButtonClicked(_ sender: UIButton) {
//        if !self.traitCollection.isRegular {
//            if let baseVC = self.splitViewController?.parent as? FTBaseShelfViewController {
//                baseVC.showSettingsPage()
//                return
//            }
//        }
        self.delegate?.performToolbarAction(self, actionType: .settings, actionView: sender)
        track("Shelf_Settings", params: [:], screenName: FTScreenNames.shelfScreen)
    }
    
    @IBAction func sideMenuBtnTapped(_ sender: Any) {
//        if let splitVC = shelfVC?.splitViewController {
//            UIView.animate(withDuration: 0.2) {
//                let displayMode: UISplitViewController.DisplayMode = splitVC.displayMode
//                if splitVC.traitCollection.isRegular {
//                    let isLandscape = self.view.window?.ftStatusBarOrientation.isLandscape ?? false
//                    if isLandscape {
//                        let screenWidth = splitVC.view.frame.width
//                        if screenWidth <= 850 {
//                            splitVC.preferredDisplayMode = (displayMode == .primaryHidden) ? .primaryOverlay : .primaryHidden
//                        } else {
//                            splitVC.preferredDisplayMode = (displayMode == .allVisible) ? .primaryHidden : .allVisible
//                            #if !targetEnvironment(macCatalyst)
//                            (self.shelfVC?.shelfToolbarController as? FTiOSShelfToolbarController)?.hideSideMenuButtonIfRequired()
//                            #endif
//                        }
//                    }
//                    else {
//                        splitVC.preferredDisplayMode = (displayMode == .primaryHidden) ? .primaryOverlay : .primaryHidden
//                    }
//                }
//                else {
//                    (splitVC.viewControllers.last as? UINavigationController)?.popViewController(animated: true)
//                }
//            }
//        } else if nil == shelfVC {
//            if self.isRegularClass() {
//                self.dismiss(animated: true, completion: nil)
//            } else {
//                if let tableView = self.tableView {
//                    super.tableView(tableView, didSelectRowAt: self.selectedIndexPath)
//                }
//                #if !targetEnvironment(macCatalyst)
//                //To hide the side panel when closing a book while the split mode is primaryOverlay
//                if UIDevice.current.isIphone() {
//                    self.delegate?.hideCategoriesPanel()
//                }
//                else if let baseVC = self.splitViewController?.parent as? FTBaseShelfiOS13ViewController {
//                    if let categoryVC = baseVC.shelfCategoryVC as? FTShelfCategoryViewController_iOS13, let splitVC = categoryVC.splitViewController {
//                        UIView.animate(withDuration: 0.2) {
//                            if splitVC.displayMode == .primaryOverlay {
//                                splitVC.preferredDisplayMode = .primaryHidden
//                            }
//                        }
//                    }
//                }
//                #endif
//               }
//        }
    }

//    private var shelfVC : FTShelfViewController? {
//        var shelfViewController: FTShelfViewController?
//        if let vc = self.splitViewController?.viewControllers.last?.children.filter({$0 is FTShelfViewController}) as? [FTShelfViewController] {
//            shelfViewController = vc.first
//        }
//        return shelfViewController
//    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        // Pass information to baseshelfiphoneVC
        self.tableView?.endEditing(true)
        if (UIDevice.current.isIphone()) {
            self.delegate?.hideCategoriesPanel()
        }
    }
}

//MARK:- FTShelfCategoryHeaderViewDelegate -
extension FTShelfCategoryViewController_iOS13 : FTiOSShelfCategoryHeaderViewDelegate
{
    func headerView(_ view: FTiOSShelfCategoryHeaderView, category: FTShelfCategoryCollection, didCollapsed collapsed: Bool) {
        //This line is commented because we are already reloading by keyPath observer > collapsed_category_
        //self.reloadSections([category.type]);
    }    
}

extension FTShelfCategoryViewController_iOS13 {
    private func addCollapseObservers() {
        if !self.isObserversAdded {
            self.isObserversAdded = true
            UserDefaults.standard.addObserver(self, forKeyPath: "collapsed_category_\(FTShelfCategoryType.user)", options: NSKeyValueObservingOptions.new, context: nil);
            UserDefaults.standard.addObserver(self, forKeyPath: "collapsed_category_\(FTShelfCategoryType.starred)", options: NSKeyValueObservingOptions.new, context: nil);
            UserDefaults.standard.addObserver(self, forKeyPath: "collapsed_category_\(FTShelfCategoryType.recent)", options: NSKeyValueObservingOptions.new, context: nil);
        }
    }
    
    private func handleObserver(forKeyPath keyPath: String) {
        if keyPath == "collapsed_category_\(FTShelfCategoryType.user)" {
            self.tableView?.endEditing(true)
            self.reloadSections([.user])
        }
        else if keyPath == "collapsed_category_\(FTShelfCategoryType.starred)" {
            self.tableView?.endEditing(true)
            self.reloadSections([.starred])
        }
        else if keyPath == "collapsed_category_\(FTShelfCategoryType.recent)" {
            self.tableView?.endEditing(true)
            self.reloadSections([.recent])
        }
    }
}

extension FTShelfCategoryViewController_iOS13: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let category = self.shelfCollections[indexPath.section];
        if category.type == .recent || category.type == .starred {
            return self.selectedItems(at: indexPath, for: session)
        }
        return []
    }

    func tableView(_ tableView: UITableView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return []
    }

    private func selectedItems(at indexPath: IndexPath, for session: UIDragSession) -> [UIDragItem] {
        let category = self.shelfCollections[indexPath.section];
        if category.type == .user || category.type == .none {
            return []
        }
        let sourceShelfItem = category.items[indexPath.item]
        let sourceURL = sourceShelfItem.URL
        let itemProvider = NSItemProvider()

        let title = sourceURL.deletingPathExtension().lastPathComponent
        let userActivityID = FTNoteshelfSessionID.openNotebook.activityIdentifier
        let userActivity = NSUserActivity(activityType: userActivityID)
        userActivity.title = title
        var userInfo = userActivity.userInfo ?? [AnyHashable : Any]();
        let docPath = sourceURL.relativePathWRTCollection();
        userInfo[LastOpenedDocumentKey] = docPath
        if docPath.deletingLastPathComponent.pathExtension == groupExtension {
            userInfo[LastOpenedGroupKey] = docPath.deletingLastPathComponent
        }

        if let collectionName = docPath.collectionName() {
            userInfo[LastSelectedCollectionKey] = collectionName;
        }
        userActivity.userInfo = userInfo
        itemProvider.registerObject(userActivity, visibility: .all)

        itemProvider.suggestedName = sourceShelfItem.URL.deletingPathExtension().lastPathComponent

        //************************************
//        if let shelfItem = sourceShelfItem as? FTShelfItemProtocol {
//            let itemToExport = FTItemToExport.init(shelfItem: shelfItem)
//
//            itemProvider.registerFileRepresentation(forTypeIdentifier: UTI_TYPE_NOTESHELF_BOOK, fileOptions: [.openInPlace], visibility: .all) { completionHandler in
//                let dataProgress:Progress = Progress()
//                let contentgenerator = FTNBKContentGenerator()
//                contentgenerator.generateSupportContent(forItem: itemToExport, andCompletionHandler: { (item, error, _) -> (Void) in
//                    if error == nil, let filePath = item?.representedObject as? String {
//                        let fileURL = URL.init(fileURLWithPath: filePath)
//                        completionHandler(fileURL, true, nil)
//                    }
//                    else
//                    {
//                        completionHandler(nil, false, error)
//                    }
//                });
//                return dataProgress
//            }
//
//            let dragContext = FTDragAssociatedInfo.init(with: shelfItem)
//            dragContext.focusedIndexPath = indexPath
//            dragContext.allowMove = false
//            session.localContext = dragContext
//            if((session.localContext) != nil) {
//                let dragItem = UIDragItem(itemProvider: itemProvider)
//                dragItem.localObject = sourceShelfItem
//
//                dragItem.previewProvider  = { () -> UIDragPreview? in
//                    let previewImageView = UIImageView()
//                    previewImageView.frame =  CGRect(x: 0,y: 0,width: 137,height: 170)
//                    previewImageView.layer.cornerRadius = 3.0
//                    if let cell = self.tableView?.cellForRow(at: indexPath) as? FTShelfCategoryRecentEntryTableViewCell {
//                        previewImageView.image = cell.imageViewIcon?.image ?? UIImage(named: "covergray")
//                    }
//                    return UIDragPreview(view: previewImageView)
//                }
//
//                return [dragItem]
//            }
//        }
        return []
    }
}
