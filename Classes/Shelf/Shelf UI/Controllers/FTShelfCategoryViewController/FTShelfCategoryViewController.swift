//
//  FTShelfCategoryViewController.swift
//  Noteshelf
//
//  Created by Amar on 07/01/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

import FTDocumentFramework

enum FTCategoryDisplayMode: Int {
    case shelf
    case notebook
}
enum FTCategoryToolbarActionType : Int
{
    case settings
    case addNew
}
private let screen_width_extra_offset : CGFloat = 80

private let ShelfCategoryHeaderViewIdentifier = "ShelfCategoryHeaderViewIdentifier"
class FTShelfCategoryViewController : UIViewController, FTCustomPresentable
{
    var customTransitioningDelegate = FTCustomTransitionDelegate(with: .interaction)
    var displayMode: FTCategoryDisplayMode = .shelf
    @IBOutlet weak var optionsButton: UIButton?
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var overLayBG : UIView?
    @IBOutlet weak var equalWidthConstraint : NSLayoutConstraint? //User only in iPad
    @IBOutlet weak var widthConstraint : NSLayoutConstraint? // Used Only in iPhone
    @IBOutlet weak var leadingConstarint : NSLayoutConstraint? // Used Only in iPhone
    @IBOutlet weak var blurView : UIView? // Used Only in iPhone
    private(set) var shelfCollections = [FTShelfCategoryCollection]();
    private(set) weak var editingShelfItemCollection: FTShelfItemCollection?;
    private var isViewAppeared = false
    weak var shelfItemCollection: FTShelfItemCollection? {
        didSet {
            //***********Doing here as we don't get windowScene for compact mode in shelfViewController
            if self.displayMode == .shelf {
                if let userActivity = self.view.window?.windowScene?.userActivity{
                    userActivity.isAllNotesMode = self.shelfItemCollection?.isAllNotesShelfItemCollection ?? false
                }
            }
            //***********
        }
    }

    weak var delegate : FTShelfCategoryDelegate?;
    var isEnableTextFiled : Bool = true
    fileprivate var scrollingCompletionBlock : ( () -> Void)?;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        disableWidthConstraintIfNotRequired()
        removeBlurView()
        self.reloadCollectionsNow()
        addCategoriesObservers()
        self.view.backgroundColor = UIColor.appColor(.finderBgColor)
//        self.view.addVisualEffectBlur(style: .systemThickMaterial, cornerRadius: 0)
//        self.tableView?.dropDelegate = self;
        addKeyboardObservers()
        
        // To show migrated data in real time
        NotificationCenter.default.addObserver(self, selector: #selector(FTShelfCategoryViewController.reloadCollectionsWithLatestData), name: NSNotification.Name(rawValue: FTSuccessfullyMigratedNS1Notification), object: nil);
        
        if self.displayMode == .notebook {
            FTCLSLog("SidePanel - Opened");
        }
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.handleTapOnOverlay))
        self.overLayBG?.addGestureRecognizer(tapGesture)
        self.navigationController?.navigationBar.sizeToFit()
        //self.tableView.contentInsetAdjustmentBehavior = .never
    }
    
    private func navigateToAllnotes() {
        if !shelfCollections.isEmpty {
            let items = shelfCollections[0].items
            if !items.isEmpty, let allNotesItem = items.first as? FTShelfItemCollectionAll {
                self.didSelectItem(allNotesItem, animation: false)
            }
        }
    }
    
    @objc private func handleTapOnOverlay() {
        self.delegate?.didTapOnCategoriesOverlay()
    }
    
    func shelfViewDidMovedToFront(with item : FTDocumentItem)
    {
        //self.addCategoriesObservers();
        //self.reloadCollectionsWithLatestData();
    }
    
    func shelfWillMovetoBack()
    {
       // NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !isViewAppeared {
            isViewAppeared = true
            navigateToAllnotes()
        }
    }
    
    deinit{
        #if DEBUG
        debugPrint("deinit : \(self.classForCoder)")
        #endif
        if self.displayMode == .notebook {
            FTCLSLog("SidePanel - Closed");
        }
        removeObserversIfNeeded()
    }
    
    func removeObserversIfNeeded() {
        NotificationCenter.default.removeObserver(self)
    }
    //MARK:- Categories Observers
    private func addCategoriesObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(shelfCategoryDidGetRemoved(_:)), name: NSNotification.Name.collectionRemoved, object: nil)

        NotificationCenter.default.addObserver(forName: FTCategoryItemsDidUpdateNotification,
                                               object: nil,
                                               queue: nil)
        { [weak self] (notification) in
            if let notificationOBJ = notification.object as? FTShelfCollectionAndEventType{
                let sectionType = notificationOBJ.collectionType
                if notificationOBJ.collectionType == .user {
                    self?.filterUserCategoriesIfneeded()
                }
                self?.reloadSections([sectionType]);
                if notificationOBJ.collectionEventType == .collectionAdded,let shelfCollectionItem = self?.shelfItemCollection {
                    self?.scrollToNewlyCreatedUserCategoryItem(collectionItem:shelfCollectionItem)
                }
            }
        }
    }
    
    //This is temp fix to remove allNotes and uncategorized.Need to refactor at root level
    private func filterUserCategoriesIfneeded(){
        let collections = self.shelfCollections
        collections.forEach { eachCollection in
            if eachCollection.type == .user {
                let items = eachCollection.items.filter {($0 as? FTShelfItemCollection)?.collectionType != .allNotes && ($0 as? FTShelfItemCollection)?.displayTitle != NSLocalizedString("shelf.category.unCategorized", comment: "Uncategorized") }
                eachCollection.items = items
            }
        }
        self.shelfCollections = collections
    }
    
    private func addKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.willShowHideKeyboard(_:)), name: UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.willShowHideKeyboard(_:)), name: UIResponder.keyboardWillHideNotification, object: nil);
    }
    
    @objc private func reloadCollectionsWithLatestData() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(#selector(reloadCollectionsNow), with: nil, afterDelay: 0.1)
    }
    
    @objc private func reloadCollectionsNow() {
        self.loadCategories {[weak self] in
            self?.tableView?.endEditing(true)
            self?.tableView?.reloadData();
        }
    }
    func loadCategories(_ onCompletion: @escaping () -> ()){
        FTNoteshelfDocumentProvider.shared.categoryShelfs {[weak self] (collections) in
            self?.shelfCollections = collections
            onCompletion()
        }
//        FTNoteshelfDocumentProvider.shared.shelfs {[weak self] (collections) in
//            self?.shelfCollections = collections
//            onCompletion()
//        };
    }
    var categoryWidth : CGFloat {
        let screenMainWidth = UIScreen.main.getWidth()
        return screenMainWidth - screen_width_extra_offset
    }
    func disableWidthConstraintIfNotRequired() {
        if(UIDevice.current.isIphone()) {
            if self.displayMode == .shelf {
                self.equalWidthConstraint?.isActive = false
            }
            self.widthConstraint?.constant = self.categoryWidth + 10 //Due to some overlay UI glitch
        } else {
            self.widthConstraint?.isActive = false
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.navigationController?.isNavigationBarHidden = false
        disableWidthConstraintIfNotRequired()
    }
    //MARK:- Custom -
    private func didSelectItem(_ item : FTDiskItemProtocol, animation: Bool = true) {
        if let collection = item as? FTShelfItemCollection {
            self.selectItem(collection)
            let storyboard = UIStoryboard(name: "FTShelfItems", bundle: nil)
            if let shelfItemsViewController = storyboard.instantiateViewController(withIdentifier: "FTSidePanelItemsViewController") as? FTSidePanelItemsViewController {
                shelfItemsViewController.sidePanelDelegate = self.delegate as? FTSidePanelShelfItemPickerDelegate
                shelfItemsViewController.collection = collection;
                self.navigationController?.pushViewController(shelfItemsViewController, animated: animation)
            }
            return
        }
    }

    private func indexForCategory(type : FTShelfCategoryType) -> Int?
    {
        let index = self.shelfCollections.firstIndex(where: { (eachCategory) -> Bool in
            return (eachCategory.type == type);
        });
        return index;
    }
    
    private func category(type : FTShelfCategoryType) -> FTShelfCategoryCollection?
    {
        let category = self.shelfCollections.first { (eachCategory) -> Bool in
            return (eachCategory.type == type);
        }
        return category;
    }

    func reloadSections(_ sections : [FTShelfCategoryType])
    {
        var sectionsToReload : IndexSet = [];
        sections.forEach { (eachSection) in
            if let section = self.indexForCategory(type: eachSection) {
                sectionsToReload.insert(section);
            }
        }
        #if targetEnvironment(macCatalyst)
            CATransaction.begin();
            CATransaction.setDisableActions(true);
            self.tableView?.reloadSections(sectionsToReload, with: .automatic)
            CATransaction.commit()
        #else
            self.tableView?.reloadSections(sectionsToReload, with: .automatic)
        #endif
    }
    
    private func indexPathForShelfItem(item : FTShelfItemProtocol) -> NSIndexPath?
    {
        let type: FTShelfCategoryType = (item.shelfCollection is FTShelfItemCollectionFavorites) ? .starred : .recent
        let index = self.shelfCollections.firstIndex(where: { (eachCategory) -> Bool in
            return (eachCategory.type == type);
        });
        if let sectionIndex = index, self.shelfCollections[sectionIndex].isCollapsed == false {
            let sectionItems = self.shelfCollections[sectionIndex].items
            if(sectionItems.isEmpty) {
                return nil;
            }
            
            let count = sectionItems.count
            for index in 0...count-1
            {
                let eachItem = sectionItems[index]
                if(eachItem.URL.path == item.URL.path) {
                    return NSIndexPath.init(row: index, section: sectionIndex)
                }
            }
        }
        return nil
    }
    
    func scrollToItem(item : FTShelfItemProtocol,animate : Bool, onCompletion : (() -> Void)?)
    {
        if let indexPath = self.indexPathForShelfItem(item: item) {
            if let visibleIndexPaths = self.tableView?.indexPathsForVisibleRows {
                if(visibleIndexPaths.contains(indexPath as IndexPath)){
                    onCompletion?()
                }
                else {
                    if(animate) {
                        self.scrollingCompletionBlock = onCompletion
                        self.tableView?.scrollToRow(at: indexPath as IndexPath, at: UITableView.ScrollPosition.none, animated: animate)
                    }
                    else {
                        self.tableView?.scrollToRow(at: indexPath as IndexPath, at: UITableView.ScrollPosition.none, animated: animate)
                        onCompletion?()
                    }
                }
            }
        }
        else{
            onCompletion?();
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.scrollingCompletionBlock?();
        self.scrollingCompletionBlock = nil;
    }
    
    func scrollToNewlyCreatedUserCategoryItem(collectionItem : FTShelfItemCollection) {
        if let categoryIndex = self.indexForCategory(type: FTShelfCategoryType.user){
            let category = self.shelfCollections[categoryIndex]
            if let row = category.items.firstIndex(where: {$0.uuid == collectionItem.uuid}), row > 0{
                if let numberOfRowsInTableview = self.tableView?.numberOfRows(inSection: categoryIndex),row < numberOfRowsInTableview{
                    self.tableView?.scrollToRow(at: IndexPath(row: row, section: categoryIndex), at: UITableView.ScrollPosition.none, animated: true)
                }
            }
        }
    }
}
//MARK:- Shelf Collection Renamne / Delete -
extension FTShelfCategoryViewController
{
    func renameCollection(atIndexPath indexPath : IndexPath, toTitle title: String)
    {
        let category = self.shelfCollections[indexPath.section];
        let items = category.items;
        guard let collection = items[indexPath.row] as? FTShelfItemCollection else {
            return;
        }
        
        FTNoteshelfDocumentProvider.shared.renameShelf(collection,
                                                       title: title,
                                                       onCompletion:
            { [weak self] (error, updatedCollection) in
                if(nil != error) {
                    UIAlertController.showConfirmationDialog(with: error!.description, message: "",
                                                             from: self,
                                                             okHandler: {
                    });
                }
                else {
                    guard let `self` = self, updatedCollection != nil else {
                        return
                    }
                    //TODO: Check for EN
//                    collection.shelfItems(.none,
//                                          parent: nil,
//                                          searchKey: nil,
//                                          onCompletion:
//                        { (items) in
//                            items.forEach({ (eachItem) in
//                                if let docItem = eachItem as? FTDocumentItemProtocol, let docID = docItem.documentUUID {
//                                    let autoBackupItem = FTAutoBackupItem.init(URL: docItem.URL, documentUUID: docID);
//                                    FTCloudBackUpManager.shared.shelfItemDidGetUpdated(autoBackupItem, dueToRename: true);
//                                }
//                                if let groupItem = eachItem as? FTGroupItemProtocol{
//                                    for item in groupItem.childrens {
//                                        if let docItem = item as? FTDocumentItemProtocol, let docID = docItem.documentUUID {
//                                            let autoBackupItem = FTAutoBackupItem.init(URL: docItem.URL, documentUUID: docID);
//                                            FTCloudBackUpManager.shared.shelfItemDidGetUpdated(autoBackupItem, dueToRename: true);
//                                        }
//                                    }
//                                }
//                            });
//                    });
                    FTCloudBackUpManager.shared.startPublish();
                    self.delegate?.shelfCategory(self, didRenameCollection: updatedCollection!);
                    self.reloadCollectionsWithLatestData();
                }
        });
    }
    func emptyTrash(_ collection : FTShelfItemCollection){
//        FTNoteshelfDocumentProvider.emptyTrashCollection(collection, onController: self) {
//            self.tableView?.reloadData()
//        }
    }
    func deleteShelfItemCollection(_ collection : FTShelfItemCollection) {
        
        let deletehandler : (FTLoadingIndicatorViewController?)->() = { [weak self] indicator in
            guard let strongSelf = self else {
                return ;
            }
            strongSelf.delegate?.shelfCategory(strongSelf, willDeleteCollection: collection);
            
            FTNoteshelfDocumentProvider.shared.moveShelfToTrash(collection,
                                                                onCompletion:
                { (error, deletedCollection) in
                    if let nserror = error {
                        nserror.showAlert(from: strongSelf);
                    }
                    else if let delCollection = deletedCollection {
                        strongSelf.delegate?.shelfCategory(strongSelf, didDeleteCollection: delCollection);
                        if let nextCollection = strongSelf.nextShelfCollectionOnDelete(delCollection) {
                            strongSelf.didSelectItem(nextCollection);
                        }
                    }
                    //Handled in closeClicked methods
                    indicator?.hide()
            });
            
        }
        
        
        if collection.childrens.isEmpty {
            deletehandler(nil)
            return
        }
        
        var title = NSLocalizedString("DeleteCategoryConfirmation", comment: "Would you like to delete Shelf?");
        if(FTNSiCloudManager.shared().iCloudOn()) {
            title = NSLocalizedString("DeleteCategoryConfirmationCloud", comment: "Would you like to delete Shelf?");
        }
        
        let alertController = UIAlertController.init(title: title, message: nil, preferredStyle: .alert);
        
        let confirmAction = UIAlertAction.init(title: NSLocalizedString("Delete", comment: "Delete"),
                                               style: .destructive,
                                               handler:
            { [weak self] (_) in
                guard let strongSelf = self else {
                    return ;
                }
                let loadingIndicatorViewController =  FTLoadingIndicatorViewController.show(onMode: .activityIndicator,
                                                                                            from: strongSelf,
                                                                                            withText: NSLocalizedString("Deleting", comment: "Deleting..."));
                
                deletehandler(loadingIndicatorViewController)
        });
        
        alertController.addAction(confirmAction);
        
        let cancelAction = UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil);
        alertController.addAction(cancelAction);
        
        self.present(alertController, animated: true, completion: nil);
    }
    
    func removeShelfItemsFromRecent(_ items : [FTShelfItemProtocol],from mode:FTRecentItemType)
    {
        FTNoteshelfDocumentProvider.shared.removeShelfItemFromList(items, mode: mode)
    }
    
    func addShelfItemToPinCollection(_ item : FTShelfItemProtocol)
    {
        if let error = FTNoteshelfDocumentProvider.shared.addShelfItemToList(item, mode: .favorites) {
            error.showAlert(from: self);
        }
    }
    
    func editShelfItemCollection(_ collection : FTShelfItemCollection?,indexPath : IndexPath? = nil)
    {
        self.editingShelfItemCollection = collection;
        if(nil == collection) {
            isEnableTextFiled = false
            self.tableView?.endEditing(true);
            self.tableView?.reloadData()
        }
        else if let path = indexPath {
            isEnableTextFiled = true
            self.tableView?.reloadRows(at: [path], with: .fade)
        }
    }
    
}


fileprivate extension FTShelfCategoryViewController
{
    func nextShelfCollectionOnDelete(_ deletedCollection : FTShelfItemCollection) -> FTShelfItemCollection?
    {
        guard let category = self.category(type: .user) else {
            return nil;
        }
        
        var shelfItemCollectionToShow: FTDiskItemProtocol?
        //If current category is being deleted
        if deletedCollection.uuid == self.shelfItemCollection?.uuid {
            var shelfItemCollections = category.items;
            guard let shelfIndex = shelfItemCollections.firstIndex(where: {$0.uuid == deletedCollection.uuid}) else {
                return nil;
            }
            shelfItemCollections.remove(at: shelfIndex);
            
            if(shelfIndex >= shelfItemCollections.count) {
                shelfItemCollectionToShow = shelfItemCollections.last;
            }
            else {
                //Choose a category with same index
                shelfItemCollectionToShow = shelfItemCollections[shelfIndex];
            }
        }
        return shelfItemCollectionToShow as? FTShelfItemCollection;
    }
    
    func indexForShelfItemCollection(atURL urlItem : URL) -> FTShelfItemCollection?
    {
        guard let category = self.category(type: .user) else {
            return nil;
        }
        
        let shelfItemCollections = category.items;
        let itemToCompare = urlItem.standardizedFileURL;
        let index = shelfItemCollections.index(where: { (item) -> Bool in
            if(item.URL.standardizedFileURL == itemToCompare) {
                return true;
            }
            return false;
        });
        if let idx = index {
            return shelfItemCollections[idx] as? FTShelfItemCollection
        }
        return nil
    }
    
}

//MARK:- UITableViewDataSource -
extension FTShelfCategoryViewController : UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.shelfCollections.count;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let category = self.shelfCollections[section];
        var rowCount = 0;
        if(!category.isCollapsed) {
            rowCount = category.items.count
        }
        return rowCount;
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let category = self.shelfCollections[indexPath.section];
        if(category.type == FTShelfCategoryType.user) && indexPath.row < category.items.count {
            let shelfItemCollection = category.items[indexPath.row];
            if self.editingShelfItemCollection?.uuid ==  shelfItemCollection.uuid {
                if isEnableTextFiled {
                    cell.isEditing = true
                }else {
                    cell.isEditing = false
                }
            }
            else {
                cell.isEditing = false;
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let category = self.shelfCollections[indexPath.section];
        
        var tableViewCell : UITableViewCell!;
        
        if(category.type == FTShelfCategoryType.user || category.type == FTShelfCategoryType.systemDefault) {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CellShelfCategory_Mac") as? FTShelfCategoryTableViewCell else {
                fatalError("Couldnot find FTShelfCategoryTableViewCell with id - CellShelfCategory_Mac")
            }
            cell.tag = indexPath.section;
            cell.textField?.tag = indexPath.row;
            cell.accessoryViewWidthConstraint?.constant = 0.0
            if category.items.count > indexPath.row,
                let shelfItemCollection = category.items[indexPath.row] as? FTShelfItemCollection {
                cell.configUI(shelfItemCollection);
                cell.isCategorySelected = (shelfItemCollection.uuid == self.shelfItemCollection?.uuid)
                cell.itemCountLabel?.text = ""
                if cell.isCategorySelected {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: kShelfCollectionItemsCountNotification), object: nil, userInfo: ["shelfItemsCount" : "\(shelfItemCollection.childrens.count)"])
                }
            } else if category.items.count == indexPath.row {
                cell.configUI(nil) // to add new category item
            }
            
            tableViewCell = cell;
        }
        else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CellShelfCategory_RecentEntry") as? FTShelfCategoryRecentEntryTableViewCell else {
                fatalError("Could not find FTShelfCategoryRecentEntryTableViewCell with id - CellShelfCategory_RecentEntry")
            }
            if category.items.count > indexPath.row,
                let item = category.items[indexPath.row] as? FTShelfItemProtocol {
                cell.configUI(item)
                if let currentItem = self.delegate?.currentShelfItemInSidePanelController() , (item.uuid == currentItem.uuid || item.URL == currentItem.URL) {
                    cell.isSelected = true
                } else {
                    cell.isSelected = false
                }
            }
            tableViewCell = cell;
        }
        return tableViewCell;
    }
}

//MARK:- UITableViewDelegate -
extension FTShelfCategoryViewController : UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = self.shelfCollections[indexPath.section]
        if category.type == .user || category.type == .systemDefault {
            if indexPath.row == category.items.count {
                (self as? FTShelfCategoryViewController_iOS13)?.showCreateCategoryAlert()
            } else if indexPath.row > category.items.count {
                
            } else {
                let collection = category.items[indexPath.row]
                self.didSelectItem(collection)
            }
        }
    }
    
    private func showCreateCategoryAlert() {
       let alertController = UIAlertController.init(title: NSLocalizedString("AddToNewCategory", comment: "New Category..."), message: nil, preferredStyle: .alert);
       alertController.addTextField(configurationHandler: { (textFiled) in
            textFiled.autocapitalizationType = UITextAutocapitalizationType.words;
            textFiled.setDefaultStyle(.defaultStyle);
            textFiled.setStyledPlaceHolder(NSLocalizedString("Untitled", comment: "Untitled"), style: .defaultStyle);
        });
        let okaction = UIAlertAction.init(title: NSLocalizedString("Create", comment: "Create"), style: .default) { [weak alertController,weak self] (_) in
            if let textFiled = alertController?.textFields?.first {
                var title = textFiled.text;
                if(nil != title) {
                    title = title!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                }
                if(nil == title || title!.isEmpty) {
                    title = NSLocalizedString("Untitled", comment: "Untitle");
                }
                self?.createCategory(title!)
                track("Shelf_QuickAccess_AddNewCategory", params: [:],screenName: FTScreenNames.shelfQuickAccess)
            }
        }
        alertController.addAction(okaction);
        let cancelAction = UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil);
        alertController.addAction(cancelAction);
        self.present(alertController, animated: true, completion: nil);
    }
    
    private func createCategory(_ title :String) {
        FTNoteshelfDocumentProvider.shared.createShelf(title) { (error, collection) in
            if let nsError = error {
                nsError.showAlert(from: self);
            }
            else if let shelfCollection = collection {
                self.delegate?.shelfCategory(self, didAddedCollection: shelfCollection);
                if let splitMode = self.splitViewController?.displayMode, (splitMode == .allVisible || splitMode == .primaryOverlay) {
                    if let isCategoriesCollapsed = self.shelfCollections.first?.isCollapsed, isCategoriesCollapsed == false {
                        self.isEnableTextFiled = false
                        self.editShelfItemCollection(shelfCollection);
                    }
                }
                if let isCategoriesCollapsed = self.shelfCollections.first?.isCollapsed, isCategoriesCollapsed == true {
                    self.shelfCollections.first?.isCollapsed = false
                }
                self.shelfItemCollection = shelfCollection;
            }
        };
    }
}

//MARK:- UITextFieldDelegate -
extension FTShelfCategoryViewController : UITextFieldDelegate
{
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.editingShelfItemCollection = nil;
        let cell = textField.superview!.superview as! FTShelfCategoryTableViewCell;
        let indexPath = IndexPath.init(row: textField.tag, section: cell.tag);
        guard let title = textField.text, !title.isEmpty,!title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
            return;
        }
        let trashCategoryTitle = NSLocalizedString("Trash", comment: "Trash");
        guard title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != trashCategoryTitle.lowercased() else {
            UIAlertController.showAlert(withTitle: "", message: String(format: NSLocalizedString("CannotUseReservedName", comment: "The name '%@' can’t be..."), trashCategoryTitle), from: self, withCompletionHandler:
                { [weak textField] in
                    textField?.becomeFirstResponder();
            });
            return;
        }
        
        if indexPath.section < self.shelfCollections.count {
            let categories = self.shelfCollections[indexPath.section].items;
            if indexPath.row < categories.count {
                let category = categories[indexPath.row]
                if title != category.displayTitle {
                    self.renameCollection(atIndexPath: indexPath, toTitle: title)
                }
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let cell = textField.superview!.superview as! FTShelfCategoryTableViewCell;
        let indexPath = IndexPath.init(row: textField.tag, section: cell.tag);
        //tableView?.scrollToRow(at: indexPath, at: UITableViewScrollPosition.middle, animated: true)
        let rect = tableView?.rectForRow(at: indexPath) ?? CGRect.zero
        tableView?.scrollRectToVisible(rect, animated: true)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        self.tableView?.reloadData()
        return true;
    }
}

//MARK:- Notifications -
extension FTShelfCategoryViewController {
    //ObservingShelfCollection
    @objc func shelfCategoryDidGetRemoved(_ notification: Notification) {
        let userInfo = notification.userInfo;
        if(nil != userInfo) {
            if let removedShelfCollections = userInfo![FTShelfItemsKey] as? [URL] {
                removedShelfCollections.forEach { (eachURL) in
                    if let object = indexForShelfItemCollection(atURL: eachURL) {
                        if let nextObject = self.nextShelfCollectionOnDelete(object) {
                            self.shelfItemCollection = nextObject;
                        }
                    }
                };
            }
        }
    }
    
    //MARK:- Keyboard
    @objc func willShowHideKeyboard(_ notification : Notification) {
        guard let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect, let window = self.view.window else {
            return
        }
        if self.splitViewController?.displayMode != UISplitViewController.DisplayMode.primaryOverlay {
            let endFrameWrtView = window.convert(endFrame, from: nil);
            let heightOfKeyboard = abs(window.bounds.size.height - endFrameWrtView.origin.y);
            if heightOfKeyboard == 0.0 {
                self.tableView?.endEditing(true)
            }
            var contentInset = self.tableView?.contentInset;
            contentInset?.bottom = heightOfKeyboard;
            self.tableView?.contentInset = contentInset!;
        }
    }
}


extension FTShelfCategoryViewController {
    
    //If user select favorite/recent book in PDFRenderView,then update the same item as selected in category
    func selectItem(_ collection : FTShelfItemCollection?) {
        if let inCollection = collection {
            if self.shelfItemCollection?.URL != inCollection.URL {
                self.shelfItemCollection = inCollection
                reloadCollectionsWithLatestData()
            }
        }
    }
    
    func AddBlurView() {
        runInMainThread {
            self.overLayBG?.isHidden = false
            self.overLayBG?.alpha = 0.0
            UIView.animate(withDuration: 0.3, animations: {
                self.overLayBG?.alpha = 0.5
            }) { (_) in
            }
        }
    }
    
    func removeBlurView() {
        UIView.animate(withDuration: 0.15, animations: {
            self.overLayBG?.alpha = 0.0
        }) { (_) in
            self.overLayBG?.isHidden = true
        }
    }
}

//protocol FTShelfCategoryDelegate : NSObjectProtocol{
//    func shelfCategory(_ viewController : UIViewController, didSelectCollection: FTShelfItemCollection);
//    func shelfCategory(_ viewController : UIViewController, didRenameCollection: FTShelfItemCollection);
//    func shelfCategory(_ viewController : UIViewController, didAddedCollection: FTShelfItemCollection);
//    func shelfCategory(_ viewController : UIViewController, willDeleteCollection : FTShelfItemCollection);
//    func shelfCategory(_ viewController : UIViewController, didDeleteCollection : FTShelfItemCollection);
//
//    func shelfCategory(_ viewController: UIViewController, didSelectShelfItem : FTShelfItemProtocol, inCollection: FTShelfItemCollection?);
//    func shelfCategory(_ viewController : UIViewController,move items:[FTShelfItemProtocol], toCollection : FTShelfItemCollection);
//    func performToolbarAction(_ viewController : UIViewController, actionType: FTCategoryToolbarActionType, actionView : UIView)
//    func didTapOnCategoriesOverlay()
//    //For iPhone
//    func hideCategoriesPanel()
//}
