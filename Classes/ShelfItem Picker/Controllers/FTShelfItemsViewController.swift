//
//  FTShelfItemsViewController.swift
//  Noteshelf
//
//  Created by Siva on 26/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import IntentsUI
import FTDocumentFramework
import FTCommon
import FTNewNotebook

@objc enum FTShelfItemsViewMode: Int {
    case dropboxBackUp
    case onedriveBackUp
    case evernoteSync
    case picker
    case movePage
    case recent
    case webdavBackUp
    case recentNotes
}

enum FTShelfItemDataMode: Equatable {
    case collection(FTShelfItemSubDataMode)
    case shelfItem(FTShelfItemSubDataMode)
    enum FTShelfItemSubDataMode {
        case normal
        case group
    }
}

protocol FTSelectNotebookForBackupDelegate: AnyObject {
    func pushToNextLevel(controller: UIViewController)
}

enum FTShelfAddNew: String {
    case notebook
    case category
    case group
}


typealias ShelItemAndMode = (item:FTShelfItemProtocol,sectionMode:FTRecentItemType)

class FTShelfItemsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,  UITextFieldDelegate, FTHorizontalPresentable {
    
    override var shouldAvoidDismissOnSizeChange: Bool {
        return true;
    }
    
    func didChangeState(to screenState: FTHotizontalScreenState) {
        
    }
    func shouldStartWithFullScreen() -> Bool{
        return false
    }

    var isResizing: Bool = false
    private let recentsMaxCount = 10
    private var containsGroupItemForMoving : Bool = false // used while moving groups
    var groupedItem : FTGroupItemProtocol?
    var selectedShelfItemsForMove: [FTShelfItemProtocol]?
    
    var horizontalTransitioningDelegate: FTHorizontalTransitionDelegate = FTHorizontalTransitionDelegate(with: FTHorizontalPresentationStyle.interaction, direction: .leftToRight)

    var mode = FTShelfItemsViewMode.picker;
    weak var shelfItemDelegate: FTShelfItemPickerDelegate?;
    weak var selectNotebookDelegate: FTSelectNotebookForBackupDelegate?

    private var dataMode = FTShelfItemDataMode.collection(.normal);
    private let addNewEntityIndex = 0;

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint?

    @IBOutlet weak fileprivate var buttonBack: UIButton?
    @IBOutlet weak internal var headerLabelTitle: UILabel?
    @IBOutlet weak fileprivate var moveButton: UIButton?
    @IBOutlet weak fileprivate var addButton: UIButton?
    
    @IBOutlet weak internal var tableView: UITableView!

    internal var indexPathSelected: IndexPath!
    fileprivate var sectionsForQuickAccess = [FTRecentItemType]()

    fileprivate var titleEntered : String?;
    
    //FTShelfItemProtocol
    var collection : FTShelfItemCollection?;
    internal lazy var collections = [FTShelfCategoryCollection]();
    internal lazy var items = [FTShelfItemProtocol]();
    fileprivate lazy var favoriteItems = [FTShelfItemProtocol]();
    internal var group: FTGroupItemProtocol?;
    
    //MARK:- UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaultNotificationCenter = NotificationCenter.default;
        defaultNotificationCenter.addObserver(self, selector: #selector(self.shelfItemDidGetAdded(_:)), name: NSNotification.Name.shelfItemAdded, object: nil);
        defaultNotificationCenter.addObserver(self, selector: #selector(self.shelfItemDidGetRemoved(_:)), name: NSNotification.Name.shelfItemRemoved, object: nil);
        defaultNotificationCenter.addObserver(self, selector: #selector(self.shelfItemDidGetUpdated(_:)), name: NSNotification.Name.shelfItemUpdated, object: nil);

//        self.tableView.contentInsetAdjustmentBehavior = .never
        self.tableView.rowHeight = UITableView.automaticDimension;
        self.tableView.estimatedRowHeight = 200;

        self.addButton?.isHidden = true;
        if canbePopped() {
            self.buttonBack?.setImage(UIImage(named: "backDark"), for: .normal);
        } else {
            self.buttonBack?.setImage(UIImage(named: "closeDark"), for: .normal);
        }

        if (self.mode == .picker || self.mode == .movePage)
            && nil == self.group {
            self.headerLabelTitle?.accessibilityLabel = "Move to";
            if collection?.displayTitle != nil {
                self.headerLabelTitle?.text = collection?.displayTitle
            } else {
                self.headerLabelTitle?.text = NSLocalizedString("MoveTo", comment: "Move to...")
            }
        }
        else if self.mode == .recent {
            self.addButton?.isHidden = false;
            self.headerLabelTitle?.text = NSLocalizedString("QuickAccess", comment: "Quick Access")
            self.headerLabelTitle?.accessibilityLabel = "QuickAccess";
        }
        else {
            self.view.backgroundColor = UIColor.appColor(.formSheetBgColor)
            if nil == self.navigationController || self.navigationController!.viewControllers.count > 1 {
                self.headerLabelTitle?.text = NSLocalizedString("Back", comment: "Back")
                if(self.mode == FTShelfItemsViewMode.dropboxBackUp){
                    self.headerLabelTitle?.text = NSLocalizedString("BackupNotebooks", comment: "Notebooks to Backup")//FTAccount.DropBox.rawValue
                }
                else if(self.mode == FTShelfItemsViewMode.onedriveBackUp){
                    self.headerLabelTitle?.text = NSLocalizedString("BackupNotebooks", comment: "Notebooks to Backup")//FTAccount.OneDrive.rawValue
                }
                else if(self.mode == FTShelfItemsViewMode.evernoteSync){
                    self.headerLabelTitle?.text = "Evernote"
                }
                if let title = self.collection?.displayTitle {
                    self.headerLabelTitle?.text = title
                }
            }
            else {
                self.headerLabelTitle?.text = NSLocalizedString("MoveTo", comment: "Move to...")
                self.headerLabelTitle?.accessibilityLabel = "Move to";
            }
        }
        self.moveButton?.isHidden = true;
        if self.mode == .recentNotes {
           self.dataMode = .shelfItem(.normal);
           self.fetchAndDisplayRecentAndPinnedItems()
       } else if nil != self.collection {
            
            let dataMode: FTShelfItemDataMode!
            if let group = self.group {
                self.headerLabelTitle?.text = group.displayTitle
                dataMode = .shelfItem(.group);
            }
            else {
                dataMode = .shelfItem(.normal);
            }
            self.dataMode = dataMode;
            
            if self.mode == .picker {
                self.moveButton?.isHidden = false;
            }
            
            self.fetchAndDisplayShelfItems();
        } else {
            self.fetchAndDisplayCollections();
        }
        
        // To update if there is groupItem in the selected items(whether in context menu or from bottom toolbar)
        if nil != self.groupedItem {
            self.containsGroupItemForMoving = true
        } else {
            let selectedGroupItems = self.selectedShelfItemsForMove?.filter({ (shelfItem) -> Bool in
               return shelfItem is FTGroupItemProtocol
            });
            
            if let items = selectedGroupItems, !items.isEmpty {
                self.containsGroupItemForMoving = true
            }
        }
        
        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: self.headerLabelTitle);
    }
    
    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        if isInsideSettings() {
            headerView.isHidden = true
            headerViewHeightConstraint?.constant = 0.0
        }
    }
    
    func isInsideSettings() -> Bool {
        return mode == .dropboxBackUp || mode == .evernoteSync || mode == .onedriveBackUp
    }
    //MARK:- Custom
    
    @IBAction func plusClicked(_ sender: Any) {
        
    }
    @IBAction func prepareForUnwind(_ segue: UIStoryboardSegue) {
    }
    
    @IBAction func unwindToViewController(_ segue: UIStoryboardSegue) {
        
    }
    
    @objc @IBAction fileprivate func closeClicked() {
        if nil != self.navigationController && self.navigationController!.viewControllers.count > 1 {
            _ = self.navigationController?.popViewController(animated: true);
        }
        else {
            self.shelfItemDelegate?.shelfItemsViewControllerDidCancel(self);
            self.dismiss(animated: true, completion: nil);
        }
    }
    
    @IBAction fileprivate func moveClicked() {
        if var newtitle = self.titleEntered?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
            switch self.dataMode {
            case .collection:
                if !newtitle.isEmpty {
                    self.createNewShelfCollection(withTitle: newtitle)
                }
                else {
                    self.titleEntered = nil
                }
            case .shelfItem(.normal):
                if self.mode == .movePage {
                    if(newtitle.isEmpty) {
                        newtitle = NSLocalizedString("Untitled", comment: "Untitle");
                    }
                    self.createNewNotebook(withTitle: newtitle)
                }
                else {
                    if(newtitle.isEmpty) {
                        newtitle = NSLocalizedString("Group", comment: "Group");
                    }
                    self.createNewGroup(withTitle: newtitle)
                }
            case .shelfItem(.group):
                if self.mode == .movePage {
                    if(newtitle.isEmpty) {
                        newtitle = NSLocalizedString("Untitled", comment: "Untitle");
                    }
                    self.createNewNotebook(withTitle: newtitle)
                } else {
                    if(newtitle.isEmpty) {
                        newtitle = NSLocalizedString("Group", comment: "Group");
                    }
                    self.createNewGroup(withTitle: newtitle)
                }
            }
        }
        else {
            if let groupItem = self.groupedItem,containsGroupItemForMoving{
                self.shelfItemDelegate?.shelfItemsViewController(self, didFinishPickingCollectionShelfItem: self.collection, groupToMove: groupItem, toGroup: self.group)
            } else if containsGroupItemForMoving {
                self.shelfItemDelegate?.shelfItemsViewController(self, didFinishPickingShelfItemsForBottomToolBar: self.collection, toGroup: self.group)
            }
            else{
                self.shelfItemDelegate?.shelfItemsViewController(self, didFinishPickingGroupShelfItem: self.group, atShelfItemCollection: self.collection, isNewlyCreated: false);
            }
        }
    }
    
    fileprivate func verifyTitle(_ title : String?, defaultValue : String) -> String
    {
        var newTitle = self.titleEntered;
        if(nil != newTitle) {
            newTitle = newTitle!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
        }
        if(nil == newTitle || newTitle!.count <= 0) {
            newTitle = defaultValue;
        }
        return newTitle ?? defaultValue;
    }
    
    //MARK:- Segue
    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any) -> Bool {
        if action == #selector(self.unwindToViewController(_:)) {
            return false;
        }
        return true;
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let navigationController = self.navigationController, let rootViewController = navigationController.viewControllers.first, rootViewController == self {
            self.closeClicked();
            return false;
        }

        if isInsideSettings() {
            self.selectNotebookDelegate?.pushToNextLevel(controller: self)
            return false
        }
        return true;
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let shelfItemsViewController = segue.destination as? FTShelfItemsViewController {
            shelfItemsViewController.mode = self.mode;
            shelfItemsViewController.shelfItemDelegate = self.shelfItemDelegate;
            shelfItemsViewController.selectedShelfItemsForMove = self.selectedShelfItemsForMove
            shelfItemsViewController.groupedItem = self.groupedItem

            if let collection = self.collection {
                shelfItemsViewController.collection = collection;
                shelfItemsViewController.group = self.items[self.indexPathSelected.row] as? FTGroupItemProtocol;
            }
            else {
                let relativeSectionIndex: Int;
                if self.mode == .picker {
                    relativeSectionIndex = self.indexPathSelected.section - 1;
                }
                else {
                    relativeSectionIndex = self.indexPathSelected.section;
                }

                let categories = self.collections[relativeSectionIndex].categories;
                shelfItemsViewController.collection = categories[self.indexPathSelected.row];
            }

        }
    }

    //MARK:- UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        switch self.dataMode {
        case .collection:
            if self.mode == .picker {
                return self.collections.count + 1;
            }
            else {
                return self.collections.count;
            }
        case .shelfItem(.normal):
            if self.mode == .picker || self.mode == .movePage {
                return 2;
            }
            else if self.mode == .recent {
                return sectionsForQuickAccess.count
            } else {
                return 1
            }
        case .shelfItem(.group):
            if self.mode == .movePage || self.mode == .picker {
                return 2;
            }
            else {
                return 1;
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.dataMode {
        case .collection:
            if self.mode == .picker {
                if section == self.addNewEntityIndex {
                    return 1;
                }
                else {
                    return self.collections[section - 1].items.count;
                }
            }
            else {
                if section < self.collections.count {
                    return self.collections[section].items.count;
                }
                else {
                    return 0;
                }
            }
        case .shelfItem(.normal):
            if self.mode == .picker || self.mode == .movePage {
                if section == self.addNewEntityIndex {
                    return 1;
                }
                else {
                    return self.items.count;
                }
            }
            else if self.mode == .recent {
                return numberOfItemsForRecent(for:section)
            } else {
                return self.items.count
            }
        case .shelfItem(.group):
            if self.mode == .movePage || self.mode == .picker {
                if section == self.addNewEntityIndex {
                    return 1;
                }
                else {
                    return self.items.count;
                }
            }
            else {
                return self.items.count;
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch self.dataMode {
        case .collection:
            if self.mode == .picker {
                if indexPath.section == self.addNewEntityIndex {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: "AddNewCell") as? FTShelfItemAddNewTableViewCell else {
                        fatalError("--- Could not find FTShelfItemAddNewTableViewCell ---")
                    }
                    cell.addNewLabel.text = NSLocalizedString("NewCategory", comment: "New Category...")
                    cell.addNewLabel.addCharacterSpacing(kernValue: -0.32)
                    cell.cellPurpose = .category
                    return cell
                }
            }
        case .shelfItem(.normal):
            if self.mode == .movePage {
                if (indexPath.section == self.addNewEntityIndex) && !containsGroupItemForMoving {
                    return self.cellAddNewShelfItem();
                }
            } else if self.mode == .picker {
                if indexPath.section == self.addNewEntityIndex && indexPath.row == self.addNewEntityIndex {
                    return self.cellAddNewShelfItem()
                }
            }
        case .shelfItem(.group):
            if self.mode == .movePage {
                if indexPath.section == self.addNewEntityIndex {
                    return self.cellAddNewShelfItem();
                }
            } else if self.mode == .picker {
                if indexPath.section == self.addNewEntityIndex && indexPath.row == self.addNewEntityIndex {
                    return self.cellAddNewShelfItem()
                }
            }
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CellShelfItem") as? FTShelfItemTableViewCell else {
            fatalError("--- Could not find FTShelfItemTableViewCell ---")
        }

        cell.mode = self.mode;
        cell.dataMode = self.dataMode
        cell.tableView = tableView;
        cell.indexPath = indexPath;
        
        cell.labelSubTitle.textColor = UIColor.appColor(.black50)
        cell.labelTitle.textColor = UIColor.headerColor
        cell.labelTitle.addCharacterSpacing(kernValue: -0.32)
        cell.cellAccessoryType = .none;
        cell.accessoryView = nil;
        cell.imageViewIcon.image = nil;
        cell.imageViewIcon2.image = nil;
        cell.imageViewIcon3.image = nil;

        cell.shadowImageView.isHidden = false;
        cell.shadowImageView2.isHidden = true;
        cell.shadowImageView3.isHidden = true;
        cell.passcodeLockStatusView.isHidden = true;
        
        var displayTitle = "";
        var isCurrent = false;

        //Checking if we are inside a collection
        cellDatabinding: if (nil != self.collection) || (self.mode == .recent) {
            
            var shelfItem : FTShelfItemProtocol!
            if self.mode == .recent {
                if let itemAndMode = itemAndModeFor(indexPath:indexPath) {
                    cell.didTapOnMoreOption = { [weak self] button in
                        self?.presentEditMenu(fromSourceView: button, itemAndMode: itemAndMode)
                    }
                    
                    shelfItem = itemAndMode.item
                }
            } else {
                shelfItem = itemForCollection(indexPath: indexPath)
            }
            
            guard shelfItem != nil else { break cellDatabinding }
            
            displayTitle = shelfItem.displayTitle;

            cell.labelSubTitle.isHidden = false;

            cell.imageViewIcon.contentMode = .scaleAspectFill;

            cell.configureView(item: shelfItem);
            
            if let groupShelfItem = shelfItem as? FTGroupItemProtocol {
                cell.cellAccessoryType = .disclosureIndicator;
                
                cell.labelSubTitle.text = groupShelfItem.itemsCountString
                cell.progressView?.isHidden = true;
                cell.removeObservers();
                cell.checkMarkButton?.setImage(nil, for: .normal)

                if let currentGroupShelfItem = self.shelfItemDelegate?.currentGroupShelfItemInShelfItemsViewController(), currentGroupShelfItem.uuid == groupShelfItem.uuid {
                    isCurrent = true;
                }
            }
            else {
                cell.updateUI(forShelfItem: shelfItem);
                
                if let currentShelfItem = self.shelfItemDelegate?.currentShelfItemInShelfItemsViewController(), ((currentShelfItem.uuid == shelfItem.uuid) || (currentShelfItem.URL == shelfItem.URL)) {
                    isCurrent = true;
                }
            }
        }
        else {
            cell.shadowImageView.isHidden = true;
            
            let relativeSectionIndex: Int;
            if self.mode == .picker {
                relativeSectionIndex = indexPath.section - 1;
            }
            else {
                relativeSectionIndex = indexPath.section;
            }
            
            //Handling list of collections
            let categories = self.collections[relativeSectionIndex].categories;
            let category = categories[indexPath.row];
            displayTitle = category.displayTitle;
            
            cell.cellAccessoryType = .disclosureIndicator;
            #if !targetEnvironment(macCatalyst)
            cell.imageViewIcon.contentMode = .left
            cell.imageViewIcon.tintColor = UIColor.init(hexString: "#383838")
            cell.imageIconLeadingConstraint?.constant = 14
            cell.imageViewIcon.image = UIImage(named: category.isUnfiledNotesShelfItemCollection ? "category_unfiled" : "category_single")
            cell.imageViewIcon.tintColor = .label
            #else
            cell.imageViewIcon.contentMode = .center;
            cell.imageViewIcon.image = UIImage(named: "popoverCategory");
            #endif
            
            cell.labelSubTitle.isHidden = true;
            
            
            if let currentShelfCollection = self.shelfItemDelegate?.currentShelfItemCollectionInShelfItemsViewController(), currentShelfCollection.uuid == category.uuid {
                isCurrent = true;
            }
        }
        
        //Current item Styling
//        cell.labelTitle.style = 0
//        cell.labelSubTitle.style = 5
        cell.labelTitle.text = displayTitle;

        if isCurrent {
//            cell.currentShelfItemIndicator?.isHidden = false
        }
        // TODO: To review this class with sameer and update below line
//        cell.selectionBackgroundView?.isHidden = isCurrent
        cell.contentView.isAccessibilityElement = true;
        cell.contentView.accessibilityTraits = UIAccessibilityTraits.none;
        if !cell.labelSubTitle.isHidden , let subTitle = cell.labelSubTitle.text, !subTitle.isEmpty {
            cell.contentView.accessibilityLabel = displayTitle.appending(subTitle);
        }
        else {
            cell.contentView.accessibilityLabel = displayTitle;
        }
        
        return cell;
    }
    
    //MARK:- UITableViewDelegate
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if self.mode == .recent {
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        if self.mode == .recent {
            let deleteAction = UIContextualAction(style: .destructive, title: NSLocalizedString("Hide", comment: "Hide") ) { (_, _, handler) in
                if let itemAndMode = self.itemAndModeFor(indexPath:indexPath) {
                    
                    if itemAndMode.sectionMode == .favorites {
                        FTNoteshelfDocumentProvider.shared.removeShelfItemFromList([itemAndMode.item], mode:.favorites)
                        self.favoriteItems.remove(at: indexPath.row)
                    } else {
                        FTNoteshelfDocumentProvider.shared.removeShelfItemFromList([itemAndMode.item], mode:.recent)
                        self.items.remove(at: indexPath.row)
                    }
                    handler(true)
                    self.arrangeRecentsDataSourceAndReload()
                } else {
                    handler(false)
                }
            }
            deleteAction.backgroundColor = UIColor.init(hexString: "CC4235")
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            return configuration
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (tableView.cellForRow(at: indexPath) as? FTShelfItemAddNewTableViewCell) != nil {
            return 44.0
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true);
        self.indexPathSelected = indexPath;
        if let cell = tableView.cellForRow(at: indexPath) as? FTShelfItemAddNewTableViewCell {
            self.handleAddNewCellAction(purpose: cell.cellPurpose)
            return
        }
        switch self.dataMode {
        case .collection:
            if self.mode == .picker {
                if indexPath.section == self.addNewEntityIndex {
                    return;
                }
            }
        case .shelfItem(.normal):
            if self.mode == .movePage {
                if indexPath.section == self.addNewEntityIndex && !containsGroupItemForMoving {
                    return;
                }
            } else if self.mode == .picker {
                if let groupItem = self.items[indexPath.row] as? FTGroupItemProtocol {
                    if groupItem.uuid == self.groupedItem?.uuid {
                        return
                    } else if let selectedItems = self.selectedShelfItemsForMove {
                        for item in selectedItems {
                            if let shelfItem = item as? FTGroupItemProtocol, shelfItem.uuid == groupItem.uuid {
                                return
                            }
                        }
                    }
                }
            }
        case .shelfItem(.group):
            if self.mode == .movePage {
                if indexPath.section == self.addNewEntityIndex && !containsGroupItemForMoving {
                    return;
                }
            } else if self.mode == .picker {
                if let groupItem = self.items[indexPath.row] as? FTGroupItemProtocol {
                    if groupItem.uuid == self.groupedItem?.uuid {
                        return
                    } else if let selectedItems = self.selectedShelfItemsForMove {
                        for item in selectedItems {
                            if let shelfItem = item as? FTGroupItemProtocol, shelfItem.uuid == groupItem.uuid {
                                return
                            }
                        }
                    }
                }
            }
        }
        if nil != self.collection {
            let shelfItem = self.items[indexPath.row];
            if shelfItem.type != RKShelfItemType.group {
                switch self.mode {
                case .dropboxBackUp:
                    fallthrough
                case .onedriveBackUp:
                    let documentItemProtocol = shelfItem as! FTDocumentItemProtocol;
                    if(!documentItemProtocol.isDownloaded) {
                        if(!documentItemProtocol.isDownloading) {
                            try? FileManager().startDownloadingUbiquitousItem(at: documentItemProtocol.URL);
                        }
                        return;
                    }
                    let cloudBackUpManager = FTCloudBackUpManager.shared;
                    guard let documentUUID = documentItemProtocol.documentUUID else {return};
                    let autoBackupItem = FTAutoBackupItem.init(URL: shelfItem.URL, documentUUID: documentUUID);
                    if(cloudBackUpManager.isBackupEnabled(autoBackupItem)) {
                        cloudBackUpManager.shelfItemDidGetDeleted(autoBackupItem);
                    }
                    self.tableView.reloadRows(at: [indexPath], with: .automatic);
                case .movePage:
                    self.shelfItemDelegate!.shelfItemsViewController(self, didFinishPickingShelfItem: shelfItem, isNewlyCreated: false);
                case .evernoteSync:
                    let documentItemProtocol = shelfItem as! FTDocumentItemProtocol;
                    if(!documentItemProtocol.isDownloaded) {
                        if(!documentItemProtocol.isDownloading) {
                            try? FileManager().startDownloadingUbiquitousItem(at: documentItemProtocol.URL);
                        }
                        return;
                    }

                    guard let documentUUID = documentItemProtocol.documentUUID else {return};
                    let evernotePublishManager = FTENPublishManager.shared;
                    evernotePublishManager.checkENSyncPrerequisite(from: self) { (success) in
                        if success {
                            if evernotePublishManager.isSyncEnabled(forDocumentUUID: documentUUID) {
                                FTENPublishManager.recordSyncLog("User disabled Sync for notebook: \(documentUUID)");
                                evernotePublishManager.disableSync(for: documentItemProtocol);
                                evernotePublishManager.disableBackupForShelfItem(withUUID: documentUUID);
                                self.tableView.reloadRows(at: [self.indexPathSelected], with: .automatic);
                            }
                            else {
                                if let docToBeOpened = FTDocumentFactory.documentForItemAtURL(shelfItem.URL) as? FTDocument {
                                    
                                    func updateENSyncRecords() {
                                        FTENPublishManager.recordSyncLog("User enabled Sync for notebook: \(documentUUID)");
                                        evernotePublishManager.showAccountChooser(self, withCompletionHandler: { [weak self] (accountType) in
                                            guard let strongSelf = self else {return;}
                                            if accountType != EvernoteAccountType.evernoteAccountUnknown {
                                                evernotePublishManager.enableSync(for: documentItemProtocol);
                                                evernotePublishManager.updateSyncRecord(forShelfItem: shelfItem, withDocumentUUID: documentUUID);
                                                evernotePublishManager.updateSyncRecord(forShelfItemAtURL: shelfItem.URL, withDeleteOption: true, andAccountType: accountType);
                                                strongSelf.tableView.reloadRows(at: [strongSelf.indexPathSelected], with: .automatic);
                                            }
                                        });
                                    }
                                    
                                    if true == docToBeOpened.isPinEnabled() {
                                        FTDocumentPasswordValidate.validateShelfItem(shelfItem: shelfItem,
                                                                                     onviewController: self)
                                        { (pin, success,_) in
                                            if success, let _pin = pin {
                                                FTDocument.keychainSet(_pin, forKey: documentUUID)
                                                updateENSyncRecords();
                                            }
                                        }
                                    }
                                    else {
                                        updateENSyncRecords();
                                    }
                                }
                            }
                        }
                    }
                default:
                    break;
                }
                return;
            }
        }
        if self.mode == .recent {
            if let item = self.itemAndModeFor(indexPath:indexPath)?.item {
                self.shelfItemDelegate?.shelfItemsViewController(self, didFinishPickingShelfItem: item, isNewlyCreated: false)
            }
        }
        else {
            if isInsideSettings() {
                pushToNextLevel()
            } else {
                self.performSegue(withIdentifier: "SelfPush", sender: nil);
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.mode == .recent {
            return 26
        } else {
            return 10
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if self.mode == .recent {
            let headerView = FTRecentsHeaderView.viewfromNib()
            let sectionMode = sectionsForQuickAccess[section]
            headerView?.titleLabel?.styleText = NSLocalizedString(sectionMode.rawValue, comment: "Section Header")            
            return headerView
        } else {
            return nil;
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let numSections = tableView.numberOfSections
        if (self.mode == .picker || self.mode == .movePage) && (section == numSections - 1){
            return 0.5
        }
        return .leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let numSections = tableView.numberOfSections
        if (self.mode == .picker || self.mode == .movePage) && (section == numSections - 1) {
            let headerView = UIView()
            headerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 0.5)
            headerView.backgroundColor = .separator
            return headerView
        }
        return nil
    }

    //MARK:- Only For Settings
    func pushToNextLevel() {
        let storyboard = UIStoryboard(name: "FTShelfItems", bundle: nil)
        if let shelfItemsViewController = storyboard.instantiateViewController(withIdentifier: FTShelfItemsViewController.className) as? FTShelfItemsViewController {
            shelfItemsViewController.mode = self.mode;
            shelfItemsViewController.shelfItemDelegate = self.shelfItemDelegate;
            shelfItemsViewController.selectNotebookDelegate = self.selectNotebookDelegate
            
            if let collection = self.collection {
                shelfItemsViewController.collection = collection;
                shelfItemsViewController.group = self.items[self.indexPathSelected.row] as? FTGroupItemProtocol;
            }
            else {
                let relativeSectionIndex: Int = self.indexPathSelected.section;

                let categories = self.collections[relativeSectionIndex].categories;
                shelfItemsViewController.collection = categories[self.indexPathSelected.row];
            }
            self.selectNotebookDelegate?.pushToNextLevel(controller: shelfItemsViewController)
        }
    }
    
    //MARK:- DataFetch
    private func fetchAndDisplayCollections() {
        FTNoteshelfDocumentProvider.shared.shelfs({ [weak self] (shelfItemCollections) in
            guard let strongSelf = self else {return;};
            
            strongSelf.collections.removeAll();
            shelfItemCollections.forEach({ [weak self] (shelfCategoryCollection) in
                guard let strongSelf = self else {return;};

                let filteredCategories = shelfCategoryCollection.categories.filter({$0.collectionType == .default})
                if !filteredCategories.isEmpty {
                    let categoryCollection = FTShelfCategoryCollection.init(categories: filteredCategories);
                    strongSelf.collections.append(categoryCollection);
                }
            });
            strongSelf.tableView.reloadData();
        });
    }
    
    fileprivate func fetchAndDisplayRecentAndPinnedItems() {
        
        var actionInProgress : [FTRecentItemType] = [.recent];
        let completionBlock : (FTRecentItemType)->() = { [weak self] (section) in
            let index = actionInProgress.firstIndex(of:section);
            if(nil != index) {
                actionInProgress.remove(at: index!);
                if(actionInProgress.isEmpty) {
                    self?.tableView.reloadData()
                }
            }
        };

//        FTNoteshelfDocumentProvider.shared.favoritesShelfItems(.byModifiedDate, parent: nil, searchKey: nil, onCompletion: { [weak self] (shelfItems) in
//            self?.favoriteItems.removeAll()
//            self?.favoriteItems.append(contentsOf: shelfItems)
//            completionBlock(.favorites);
//        })
        
        FTNoteshelfDocumentProvider.shared.recentShelfItems(.byModifiedDate, parent: nil, searchKey: nil, onCompletion: { [weak self] (shelfItems) in
            self?.items.removeAll()
            self?.items.append(contentsOf: shelfItems.prefix(self?.recentsMaxCount ?? 10))
            completionBlock(.recent);
        })
    }
    
    fileprivate func arrangeRecentsDataSourceAndReload() {
        //check whether pinned section exists or not
        let pinnedSectionIndex = self.sectionsForQuickAccess.index(where:{$0 == .favorites})
        
        //Pinned Items to be shown in the first section of the TableView
        if favoriteItems.isEmpty == false, pinnedSectionIndex == nil {
            self.sectionsForQuickAccess.insert(.favorites, at: 0)
        } else if let index = pinnedSectionIndex, favoriteItems.isEmpty {
            //Remove the section if shelf items are empty
            self.sectionsForQuickAccess.remove(at: index)
        }
        
        
        //check whether pinned section exists or not
        let recentSectionIndex = self.sectionsForQuickAccess.index(where:{$0 == .recent})
        
        //Recent Items to be shown in the after the Pinned section of the TableView
        if items.isEmpty == false, recentSectionIndex == nil {
            self.sectionsForQuickAccess.append(.recent)
        } else if let index = recentSectionIndex, items.isEmpty {
            //Remove the section if shelf items are empty
            self.sectionsForQuickAccess.remove(at: index)
        }
        self.tableView.reloadData()
    }

    private func fetchAndDisplayShelfItems() {
        let currentOrder = FTShelfSortOrder.byLastOpenedDate
        self.collection!.shelfItems(currentOrder, parent: self.group, searchKey: "") { [weak self] (shelfItems) in
            guard let strongSelf = self else {return;};

            strongSelf.items.removeAll();
            strongSelf.items.append(contentsOf: shelfItems);
            strongSelf.tableView.reloadData();
        }
    }
    
    //MARK:- AddNew
    private func cellAddNewShelfItem() -> FTShelfItemAddNewTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AddNewCell") as? FTShelfItemAddNewTableViewCell else {
            fatalError("Coulnot find FTShelfItemAddNewTableViewCell")
        }
        if self.mode == .movePage {
            cell.addNewLabel.text = NSLocalizedString("AddToNewNotebook", comment: "New Notebook..")
            cell.cellPurpose = .notebook
        } else {
            // For future purpose
            cell.addNewLabel.text = NSLocalizedString("NewGroup", comment: " NewGroup")
            cell.cellPurpose = .group
        }
        cell.addNewLabel.addCharacterSpacing(kernValue: -0.32)
        return cell
    }
    
    private func handleAddNewCellAction(purpose: FTShelfAddNew) {
        var alertTitle: String = ""
        if purpose == .notebook {
            alertTitle = NSLocalizedString("AddToNewNotebook", comment: "New Notebook..")
        } else if purpose == .category {
            alertTitle = NSLocalizedString("NewCategory", comment: "New Category")
        } else if purpose == .group {
            alertTitle = NSLocalizedString("NewGroup", comment: "NewGroup")
        }
        
        let alertController = UIAlertController.init(title: alertTitle, message: nil, preferredStyle: .alert);
        
        alertController.addTextField { (textFiled) in
            textFiled.placeholder = NSLocalizedString("Untitled", comment: "Untitled");
        }
        let okaction = UIAlertAction.init(title: NSLocalizedString("Create", comment: "Create"), style: .default) { [weak alertController,weak self] (_) in
            if let textFiled = alertController?.textFields?.first {
                var title = textFiled.text;
                if(nil != title) {
                    title = title!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                }
                if(nil == title || title!.isEmpty) {
                    title = NSLocalizedString("Untitled", comment: "Untitle");
                }
                self?.titleEntered = title
                self?.moveClicked()
            }
        }
        alertController.addAction(okaction);
        let cancelAction = UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil);
        alertController.addAction(cancelAction);
        self.present(alertController, animated: true, completion: nil);
    }
    
    fileprivate func createNewShelfCollection(withTitle title: String!) {
        FTNoteshelfDocumentProvider.shared.createShelf(title, onCompletion: { [weak self] (error, collection) in
            
            if nil == error && nil != collection {
                runInMainThread { [weak self] in
                    guard let strongSelf = self else {return;};
                    if let groupItem = strongSelf.groupedItem,strongSelf.containsGroupItemForMoving{
                        strongSelf.shelfItemDelegate?.shelfItemsViewController(strongSelf, didFinishPickingCollectionShelfItem: collection, groupToMove: groupItem, toGroup: self?.group)
                    }else if strongSelf.containsGroupItemForMoving {
                        strongSelf.shelfItemDelegate?.shelfItemsViewController(strongSelf, didFinishPickingShelfItemsForBottomToolBar: collection, toGroup: self?.group)
                    }
                    else{
                        strongSelf.shelfItemDelegate?.shelfItemsViewController(strongSelf, didFinishPickingGroupShelfItem: nil, atShelfItemCollection: collection, isNewlyCreated: true);
                    }
                }
            }
        });
    }
    
    private func createNewGroup(withTitle title: String!) {
        self.collection!.createGroupItem(title, inGroup: self.group, shelfItemsToGroup: nil, onCompletion: { [weak self] (error, groupItem) in
            
            if nil == error && nil != groupItem {
                runInMainThread { [weak self] in
                    guard let strongSelf = self else {return;};
                    if let groupedItem = strongSelf.groupedItem, strongSelf.containsGroupItemForMoving {
                        strongSelf.shelfItemDelegate?.shelfItemsViewController(strongSelf, didFinishPickingCollectionShelfItem: strongSelf.collection, groupToMove: groupedItem, toGroup: groupItem)
                    } else if strongSelf.containsGroupItemForMoving {
                        strongSelf.shelfItemDelegate?.shelfItemsViewController(strongSelf, didFinishPickingShelfItemsForBottomToolBar: strongSelf.collection, toGroup: groupItem)
                    } else {
                        strongSelf.shelfItemDelegate?.shelfItemsViewController(strongSelf, didFinishPickingGroupShelfItem: groupItem, atShelfItemCollection: strongSelf.collection, isNewlyCreated: true);
                    }
                }
            }
        });
    }
    
    private func createNewNotebook(withTitle title: String!) {
        if(self.mode == .movePage) {
            guard let del = self.shelfItemDelegate as? FTShelfItemMovePagePickerDelegate else {
                fatalError("\(String(describing: self.shelfItemDelegate)) should be of type: FTShelfItemMovePagePickerDelegate");
            }
            var collection = self.collection;
            var group = self.group;
            if(self.mode == .recent) {
                collection = self.shelfItemDelegate?.currentShelfItemCollectionInShelfItemsViewController();
                group = self.shelfItemDelegate?.currentGroupShelfItemInShelfItemsViewController();
            }
            guard let col = collection else {
                return;
            }
            del.shelfItemsView(self, didFinishWithNewNotebookTitle: title,collection:col,group:group);
            return;
        }
        
        let paperThemeLibrary = FTThemesLibrary(libraryType: FTNThemeLibraryType.papers);
        guard let defaultPaper = paperThemeLibrary.getDefaultTheme(defaultMode: .quickCreate) as? FTPaperThemeable else{
            fatalError("Failed to create default paper")
        }
        if nil == defaultPaper.customvariants{
            defaultPaper.setPaperVariants(FTBasicTemplatesDataSource.shared.getDefaultVariants())
        }
        let coverThemeLibrary = FTThemesLibrary(libraryType: FTNThemeLibraryType.covers);
        let isRandomCoverEnabled = FTUserDefaults.isRandomKeyEnabled()
        let defaultCover: FTThemeable!;
        if isRandomCoverEnabled {
            defaultCover = coverThemeLibrary.getRandomCoverTheme();
        }
        else {
            defaultCover = coverThemeLibrary.getDefaultTheme(defaultMode: .quickCreate);
        }
        let defaultCoverImage = UIImage(contentsOfFile: defaultCover.themeTemplateURL().path);
        
        let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator,
                                                                                   from: self,
                                                                                   withText: NSLocalizedString("Creating", comment: "Creating..."));
        Task {
            let generator = FTAutoTemplateGenerator.autoTemplateGenerator(theme: defaultPaper as! FTTheme, generationType: .template)
            do {
                let info = try await generator.generate()
                let tempDocURL = FTDocumentFactory.tempDocumentPath(FTUtils.getUUID());
                let ftdocument = FTDocumentFactory.documentForItemAtURL(tempDocURL);

                info.rootViewController = self;
                info.coverTemplateImage = defaultCoverImage;
                info.overlayStyle = FTCoverStyle.clearWhite
                info.isNewBook = true;
                var currentCollection = self.collection;
                if(self.mode == .recent) {
                    currentCollection = self.shelfItemDelegate?.currentShelfItemCollectionInShelfItemsViewController();
                    self.group = self.shelfItemDelegate?.currentGroupShelfItemInShelfItemsViewController();
                }
                if(nil == currentCollection) {
                    loadingIndicatorViewController.hide()
                    return;
                }

                ftdocument.createDocument(info) { [weak self] (error, success) in
                    if nil == error && success {

                        let createBlock: ()->() = {
                            currentCollection!.addShelfItemForDocument(tempDocURL,
                                                                       toTitle: title,
                                                                       toGroup: self?.group,
                                                                       onCompletion:
                                                                        { (error, item) in

                                //****************************** AutoBackup & AutoPublish
                                if nil == error, let docUUID = item?.documentUUID {
                                    FTENPublishManager.applyDefaultBackupPreferences(forItem: item, documentUUID: docUUID)
                                }
                                //******************************

                                loadingIndicatorViewController.hide { [weak self] in
                                    if let validItem = item, nil == error {
                                        runInMainThread { [weak self] in

                                            guard let strongSelf = self else {return;};
                                            strongSelf.shelfItemDelegate?.shelfItemsViewController(strongSelf, didFinishPickingShelfItem: validItem, isNewlyCreated: true);
                                        }
                                    }
                                }
                            });
                        }
                        createBlock()
                    }
                    else {
                        loadingIndicatorViewController.hide {[weak self] in
                            error?.showAlert(from: self)
                        };
                    }
                };

            } catch {
                fatalError("Error in generation")
            }
        }
    }

    @objc func shelfItemDidGetUpdated(_ notification: Notification) {
        if(self.mode == .recent) {
            if let shelfCollection = (notification.object as? FTShelfItemCollection),shelfCollection.collectionType == .recent {
                    self.tableView.reloadData();
            }
        }
    }
    
    @objc func shelfItemDidGetAdded(_ notification: Notification) {
        if let _ = notification.userInfo, let shelfCollection = self.collection {
            if(shelfCollection.uuid == (notification.object as! FTShelfItemCollection).uuid) {
                self.tableView.reloadData();
            }
        }
    }
    
    @objc func shelfItemDidGetRemoved(_ notification: Notification) {
        if let _ = notification.userInfo, let shelfCollection = self.collection {
            if(shelfCollection.uuid == (notification.object as! FTShelfItemCollection).uuid) {
                self.tableView.reloadData();
            }
        }
    }
}
//MARK:- FTRecentItemsEditMenuProtocol
extension FTShelfItemsViewController: FTRecentItemsEditMenuProtocol {
    
    func recentItemEditMenuSelected(for item: FTShelfItemProtocol, menu: FTRecentEditMenuItem) {
        switch menu {
        case .pin:
            
            if self.favoriteItems.count < maximumPinLimit {
                FTNoteshelfDocumentProvider.shared.addShelfItemToList(item, mode: .favorites)
                self.favoriteItems.append(item)
                //Remove from Recents, if it is added to pinned
                if let index = self.items.lastIndex(where: {$0.uuid == item.uuid}) {
                    self.items.remove(at: index)
                }
            } else {
                showPinningLimitReachedWarning()
            }
        case .unpin:
            FTNoteshelfDocumentProvider.shared.removeShelfItemFromList([item], mode: .favorites)
            if let index = self.favoriteItems.lastIndex(where: {$0.uuid == item.uuid}) {
                self.favoriteItems.remove(at: index)
            }
        case .removeFromRecents:
            FTNoteshelfDocumentProvider.shared.removeShelfItemFromList([item], mode: .recent)
            if let index = self.items.lastIndex(where: {$0.uuid == item.uuid}) {
                self.items.remove(at: index)
            }
        case .createSiriShortcut:
            FTSiriShortcutManager.shared.createSiriShortcut(for:item, onController: self)
        case .editSiriShortcut(let voiceShortcut):
            FTSiriShortcutManager.shared.editSiriShortcut(for: voiceShortcut, onController: self)
        }
        arrangeRecentsDataSourceAndReload()
    }
    
    fileprivate func showPinningLimitReachedWarning() {
        let alertMessage = String(format:NSLocalizedString("MaximumPinnedWarning", comment: "Maximum number of items pinned..."), maximumPinLimit);
        UIAlertController.showAlert(withTitle: "", message: alertMessage, from: self, withCompletionHandler: nil)
    }
    
    //present EditMenu
    func presentEditMenu(fromSourceView sourceView:UIView, itemAndMode:ShelItemAndMode) {
        FTRecentItemsEditMenuViewController.showAsPopover(fromSourceView: sourceView, overViewController: self, itemAndMode: itemAndMode, withDelegate: self)
    }
    
}

//MARK- Recents and Pinned Items Helper methods
extension FTShelfItemsViewController {
    
    fileprivate func numberOfItemsForRecent(for section:Int) -> Int {
        if sectionsForQuickAccess.count > section {
            let sectionMode = sectionsForQuickAccess[section]
            switch sectionMode {
            case .recent:
                return items.count
            case .favorites:
                return favoriteItems.count
            }
        } else {
            return 0
        }
    }
    
    internal func itemAndModeFor(indexPath:IndexPath) -> ShelItemAndMode? {
        if self.mode == .recent, sectionsForQuickAccess.count > indexPath.section {
            let sectionMode = sectionsForQuickAccess[indexPath.section]
            switch sectionMode {
            case .recent:
                return (items[indexPath.row], .recent)
            case .favorites:
                return (favoriteItems[indexPath.row], .favorites)
            }
        } else {
            return nil
        }
    }
    
    internal func itemForCollection(indexPath:IndexPath) -> FTShelfItemProtocol? {
        if self.collection != nil && !self.items.isEmpty {
            return self.items[indexPath.row]
        } else {
            return nil
        }
    }
}
