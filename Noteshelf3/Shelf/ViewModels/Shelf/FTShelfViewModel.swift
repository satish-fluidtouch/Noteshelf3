//
//  FTShelfViewModel.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 12/05/22.
//

import SwiftUI
import Combine
import FTNewNotebook
import FTCommon
import FTTemplatesStore

protocol FTShelfViewModelProtocol: AnyObject {
    func showPaperTemplateFormSheet()
    func showDropboxErrorInfoScreen()
    func showEvernoteErrorInfoScreen()
    func showSettings()
    func showNewBookPopverOnShelf()
    func didClickImportNotebook()
    func openNotebook(_ shelfItem : FTShelfItemProtocol, shelfItemDetails: FTCurrentShelfItem?, animate : Bool, isQuickCreate: Bool, pageIndex: Int?)
    func setLastOpenedGroup(_ groupURL : URL?)
    func showAlertForError(_ error: NSError?)
    func hideCurrentGroup(animated: Bool,onCompletion: (() -> Void)?)
    func moveItemsToTrash(items:[FTShelfItemProtocol], _ onCompletion:(([FTShelfItemProtocol]) -> Void)?)
    func deleteItems(_ items : [FTShelfItemProtocol],  shouldEmptyTrash:Bool, onCompletion: @escaping((Bool) -> Void))
    func restoreShelfItem( items : [FTShelfItemProtocol],onCompletion:@escaping((Bool) -> Void))
    func favoriteShelfItem(_ item: FTShelfItemProtocol,toPin: Bool)
    func showMoveItemsPopOverWith(selectedShelfItems: [FTShelfItemProtocol])
    func duplicateDocuments(_ items : [FTShelfItemProtocol], onCompletion: @escaping((Bool) -> Void))
    func renameDocuments(_ items : [FTShelfItemProtocol], onCompletion: @escaping(() -> Void))
    func showCoverViewOnShelfWith(models: [FTShelfItemViewModel])
    func changeCoverForShelfItem(_ items: [FTShelfItemProtocol], withTheme theme: FTThemeable, onCompletion: @escaping (() -> Void))
    func beginImportingOfContentTypes(_ items:[FTImportItem],completionHandler: ((Bool,[FTShelfItemProtocol]) -> Void)?)
    func shareShelfItems(_ items:[FTShelfItemProtocol],onCompletion: @escaping(() -> Void))
    func moveShelfItem(_ items: [FTShelfItemProtocol], ofCollection collection: FTShelfItemCollection, toGroup group: FTGroupItemProtocol?, onCompletion: @escaping (() -> Void))
    func groupShelfItems(_ items: [FTShelfItemProtocol], ofColection collection: FTShelfItemCollection,parentGroup: FTGroupItemProtocol?, withGroupTitle title: String, showAlertForGroupName: Bool, onCompletion: @escaping (() -> Void))
    func showGlobalSearchController()
    func showInEnclosingFolder(forItem shelfItem: FTShelfItemProtocol)
    func createNewNotebookInside(collection: FTShelfItemCollection, group: FTGroupItemProtocol?,notebookDetails: FTNewNotebookDetails?,isQuickCreate: Bool, mode:ThemeDefaultMode, onCompletion: @escaping (NSError?, _ shelfItem:FTShelfItemProtocol?) -> ())
    func migrateBookToNS3(shelfItem: FTShelfItemProtocol)
    func openGetInspiredPDF(_ url: URL,title: String);
    func openDiscoveryItemsURL(_ url:URL?)
}
protocol FTShelfCompactViewModelProtocol: AnyObject {
    func didChangeSelectMode(_ mode: FTShelfMode)
}
class FTShelfViewModel: NSObject, ObservableObject {
    
    // MARK: Private Properties
    private var cancellables = [AnyCancellable]()
    private var cancellables1 = Set<AnyCancellable>()
    
    private(set) var toolbarViewModel: FTShelfBottomToolbarViewModel =  FTShelfBottomToolbarViewModel()
    private(set) var shelfItemContextualMenuViewModel: FTShelfItemContextualMenuViewModel = FTShelfItemContextualMenuViewModel()
    private var isObserversAdded: Bool = false
    private var isRecentObserversAdded: Bool = false
    private var currentActiveShelfItem: FTCurrentShelfItem?
    private var groupItemCache = [String: FTGroupItemViewModel]();
    private var notebookItemCache = [String: FTShelfItemViewModel]();

    weak var groupViewOpenDelegate: FTShelfViewDelegate?
    var didTapOnSeeAllNotes: (() -> Void)?

    // MARK: Published variables
    @Published var mode: FTShelfMode = .normal {
        didSet {
            addOrRemoveObserversBasedOnMode()
            updateTopSectionNBCreationButtonsVisiblity()
        }
    }
        
    @Published var shelfItems: [FTShelfItemViewModel] = []
    {
        didSet {
            self.notesCount = shelfItems.count;
            subscribeToShelfItemChanges()
            self.updateGetStartedInfoWithDelay()
        }
    }
    
    @Published var currentDraggedItem: FTShelfItemViewModel?
    @Published var highlightItem: FTShelfItemViewModel?
    @Published var isLoadingShelf: Bool = false
    @Published var showNoShelfItemsView: Bool = false
    @Published var fadeDraggedShelfItem: FTShelfItemViewModel?
    @Published var showDropOverlayView: Bool = false
    @Published var reloadShelfItems: Bool = false
    @Published var tagsForThisBook: [FTTagModel] = []
    @Published var allowHitTesting: Bool = true
    @Published var showCompactBottombar: Bool = false
    @Published var showNotebookModifiedDate: Bool = UserDefaults.standard.bool(forKey: "Shelf_ShowDate")
    @Published var orientation = UIDevice.current.orientation
    @Published var isSidebarOpen: Bool = true
    @Published var notesCount: Int = 0 {
        didSet {
            if(isInHomeMode && notesCount != oldValue) {
                if self.groupItem == nil { // only posting count for collection children, not when inside a group.
                    NotificationCenter.default.post(name: Notification.Name(rawValue: shelfCollectionItemsCountNotification), object: nil, userInfo: ["shelfItemsCount" : notesCount, "shelfCollectionTitle": "\(collection.displayTitle)"])
                }
            }
        }
    }
    @Published var shouldShowGetStartedInfo: Bool = FTUserDefaults.isFirstLaunch()
    
    @Published var canShowCreateNBButtons: Bool = true
    
    // MARK: Normal Variables
    var collection: FTShelfItemCollection {
        didSet {
            reset()
            reloadShelfItems = true // on change in current collection in sidebar bar we are reloading the shelf
        }
    }
    weak var groupItem: FTGroupItemProtocol?
    weak var selectedSideBarItem : FTSideBarItem?
    weak var delegate: FTShelfViewModelProtocol?
    weak var compactDelegate: FTShelfCompactViewModelProtocol?
    weak var tagsControllerDelegate: FTTagsViewControllerDelegate?

    var updateItem: FTShelfItemViewModel?
    var shelfDidLoad: Bool = false
    var isInHomeMode: Bool = false
    
    init(collection: FTShelfItemCollection, groupItem: FTGroupItemProtocol? = nil) {
        self.collection = collection
        self.groupItem = groupItem
        super.init()
        subscribeToShelfItemChanges()
        toolbarViewModel.delegate = self
        self.addContextualMenuOerationsObserver()
        canShowCreateNBButtons = !isNS2Collection
    }
    
    init(sidebarItemType: FTSideBarItemType){
        isInHomeMode = true
        self.collection = FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection
        super.init()
        subscribeToShelfItemChanges()
        toolbarViewModel.delegate = self
        self.addContextualMenuOerationsObserver()
    }
    
    // MARK: Computed variables
    var areAllItemsSelected: Bool {
        shelfItems.filter({ $0.isSelected }).count == shelfItems.count
    }
    var navigationTitle: String {
        get {
            let title: String
            if mode == .normal && collection.collectionType == .allNotes {
                title = isInHomeMode ? (self.shouldShowGetStartedInfo ? "" : "sidebar.topSection.home".localized) : collection.displayTitle
            } else if mode == .normal && collection.collectionType != .allNotes {
                if let groupItem = groupItem {
                    title = groupItem.displayTitle
                } else {
                    title = collection.displayTitle
                }
            } else {
                let selectedCount = shelfItems.filter({ $0.isSelected }).count
                if selectedCount > 0 {
                    title = String(format: "sidebar.allTags.navbar.selected".localized, String(describing: selectedCount))
                } else {
                    title = "shelf.navmenu.selectNotes".localized
                }
            }
            return title
        }
    }
    var showNewNoteView: Bool {
        return (collection.isAllNotesShelfItemCollection || collection.isMigratedCollection || collection.isDefaultCollection)
    }
    var canShowNewNoteNavOption: Bool {
        return !(collection.isStarred || collection.isTrash || hideNS3NotesCreationOptions)
    }
    var canShowStarredIconOnNB: Bool {
        return !(collection.isTrash)
    }
    var supportsDragAndDrop: Bool {
        !(collection.isAllNotesShelfItemCollection || collection.isStarred || collection.isTrash || isNS2Collection)
    }
    var supportsDrop: Bool {
       (isInHomeMode || !(collection.isStarred || collection.isTrash || isNS2Collection))
    }
    var disableBottomBarItems: Bool {
        !shelfItems.contains(where: { $0.isSelected })
    }
    
    var selectedShelfItems: [FTShelfItemProtocol] {
        var selectedItems =  shelfItems.filter({$0.isSelected}).compactMap({$0.model})
        if selectedItems.count == 0, let selectedItemUsingContexualMenu = self.updateItem?.model {
            selectedItems = [selectedItemUsingContexualMenu]
        }
        return selectedItems
    }

    var isNS2Collection: Bool {
        if collection.isNS2Collection() {
            return true
        }
        return false
    }

    var hideNS3NotesCreationOptions: Bool {
        return isNS2Collection
    }

    var canShowSearchOption: Bool {
        return !isNS2Collection
    }

    var canShowNotebookUpdateOptions: Bool {
        return !isNS2Collection
    }

    var shouldShowNS3MigrationHeader: Bool {
        return isNS2Collection
    }
    
    
    // MARK: Mutating functions
    func selectAllItems() {
        updateShelfItemsSelectionStatusTo(true)
    }
    
    func deselectAllItems() {
        updateShelfItemsSelectionStatusTo(false)
    }
    
    func finalizeShelfItemsEdit() {
        updateShelfItemsSelectionStatusTo(false)
    }
    func subscribeToShelfItemChanges(){
        self.cancellables.removeAll()
        self.shelfItems.forEach({ [weak self] in
            let item = $0.objectWillChange.sink(receiveValue: { self?.objectWillChange.send() })
            self?.cancellables.append(item)
        })
    }
    func getShelfItemWithUUID(_ uuid: String) -> FTShelfItemViewModel? {
        self.shelfItems.first(where: {$0.model.uuid == uuid})
    }
    deinit {
        removeObserversForShelfItems()
        //print("deinit in shelfviewmodel", self.groupItem?.displayTitle)
    }
    func removeObserversForShelfItems() {
        isObserversAdded = false
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.shelfItemAdded, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.shelfItemRemoved, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.shelfItemUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ShelfItemDropOperationFinished"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: FTShelfShowDateChangeNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: shelfCollectionItemsCountNotification), object: nil)
    }
    func addObserversForShelfItems(){
        if isObserversAdded {
            return
        }
        self.addObservers()
    }
    
    func reloadShelf(animate: Bool = true){
        Task {
            await fetchShelfItems(animate: animate);
        }
    }
    
    func resetShelfModeTo(_ mode: FTShelfMode) {
        if self.mode != mode {
            self.finalizeShelfItemsEdit()
            self.mode = mode
        }
    }
    func shelfWillMovetoBack() {
        self.removeObserversForShelfItems()
    }
    
    func shelfViewDidMovedToFront() {
        self.addObserversForShelfItems()
        self.reloadShelf(animate: true);
    }
    
    func endDragAndDropOperation(){
        self.currentDraggedItem = nil
        self.fadeDraggedShelfItem = nil
    }
    
    func setcurrentActiveShelfItemUsing(_ item: FTShelfItemProtocol, isQuickCreated: Bool){
        self.currentActiveShelfItem = FTCurrentShelfItem(item, isQuickCreated: isQuickCreated)
    }
    
    func getCurrentActiveShelfItem() -> FTCurrentShelfItem?{
        return self.currentActiveShelfItem
    }
    
    func setcurrentActiveShelfItem(_ item: FTCurrentShelfItem){
        self.currentActiveShelfItem = item
    }

    private func groupItemFor(_ item: FTGroupItemProtocol) -> FTGroupItemViewModel? {
        return groupItemCache[item.uuid];
    }
    private func shelfItemFor(_ item: FTShelfItemProtocol) -> FTShelfItemViewModel? {
        return notebookItemCache[item.uuid];
    }
    
    func createShelfItemsFromData(_ shelfItemsData: [FTShelfItemProtocol]) -> [FTShelfItemViewModel]{
        
        var newCache = [String: FTGroupItemViewModel]();
        var shelfItemNewCache = [String: FTShelfItemViewModel]();
        let items: [FTShelfItemViewModel] = shelfItemsData.map { [weak self]  item -> FTShelfItemViewModel in
            if let groupItem = item as? FTGroupItemProtocol {
                let groupToreturn: FTGroupItemViewModel
                if let item = self?.groupItemFor(groupItem) {
                    groupToreturn = item
                }
                else {
                    groupToreturn = FTGroupItemViewModel(model: groupItem);
                }
                newCache[groupItem.uuid] = groupToreturn;
                return groupToreturn;
            } else {
                let shelfItemToreturn: FTShelfItemViewModel
                if let item = self?.shelfItemFor(item) {
                    shelfItemToreturn = item
                }
                else {
                    shelfItemToreturn = FTShelfItemViewModel(model: item);
                }
                shelfItemNewCache[item.uuid] = shelfItemToreturn;
                return shelfItemToreturn;
            }
        }
        self.notebookItemCache = shelfItemNewCache
        groupItemCache = newCache;
        return items
    }
    
    func addOrRemoveObserversBasedOnMode(){
        if self.mode == .selection {
            self.removeObserversForShelfItems()
        }else {
            self.addObserversForShelfItems()
        }
    }

    func presentPaperTemplateFormsheet() {
        self.delegate?.showPaperTemplateFormSheet()
    }
    
    func reset() {
        self.shelfDidLoad = false
        self.showNoShelfItemsView = false
        self.showDropOverlayView = false
        self.tagsForThisBook = []
        self.allowHitTesting = true
    }
}

// MARK: Private
private extension FTShelfViewModel {
    func updateTopSectionNBCreationButtonsVisiblity() {
        withAnimation {
            canShowCreateNBButtons = mode == .normal
        }
    }
    func updateGetStartedInfoWithDelay(){
        self.perform(#selector(updateShowingGetStartedInfoStatus), with: nil, afterDelay: 0.7)
    }
    @objc func updateShowingGetStartedInfoStatus() {
        withAnimation {
            if isInHomeMode {
                if shelfItems.count > 0 {
                    FTUserDefaults.setFirstLaunch(false)
                    self.shouldShowGetStartedInfo = false
                } else {
                    if !FTUserDefaults.isFirstLaunch() {
                        FTUserDefaults.setFirstLaunch(true)
                        self.shouldShowGetStartedInfo = true
                    }
                }
            }else {
                if shelfItems.count > 0 {
                    FTUserDefaults.setFirstLaunch(false)
                    self.shouldShowGetStartedInfo = false
                }
            }
        }
    }
    func addContextualMenuOerationsObserver(){
        self.shelfItemContextualMenuViewModel.$performAction
            .dropFirst()
            .sink { [weak self] option in
                guard let self = self else { return }
                print("choosen option",option?.displayTitle ?? "")
                if let option = option {
                    self.performContexualMenuOperation(option)
                }
            }
            .store(in: &cancellables1)
    }
    
    @objc func handleShowDateStatusChange() {
        self.showNotebookModifiedDate = UserDefaults.standard.bool(forKey: "Shelf_ShowDate")
    }
    
    func updateShelfItemsSelectionStatusTo(_ status: Bool) {
        for index in 0..<shelfItems.count {
            shelfItems[index].isSelected = status
        }
    }
    
    func addObservers() {
        if(isObserversAdded) {
            return;
        }
        isObserversAdded = true;
        NotificationCenter.default.addObserver(self, selector: #selector(shelfItemDidGetAdded(_:)), name: NSNotification.Name.shelfItemAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shelfItemDidGetRemoved(_:)), name: NSNotification.Name.shelfItemRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shelfitemDidgetUpdated(_:)), name: NSNotification.Name.shelfItemUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(groupitemDidgetAdded(_:)), name: NSNotification.Name.groupItemAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(groupitemDidgetAdded(_:)), name: NSNotification.Name.groupItemRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shelfItemDropOperationFinished(_:)), name: NSNotification.Name("ShelfItemDropOperationFinished"), object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(splitDisplayChangeHandler(_:)) , name: NSNotification.Name("SplitDisplayModeChangeNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleShowDateStatusChange), name: Notification.Name(rawValue: FTShelfShowDateChangeNotification), object: nil)
    }
    @objc func splitDisplayChangeHandler(_ notification: Notification) {
        if let userInfo = notification.userInfo, let displayModeRawvalue = userInfo["splitDisplayMode"] as? Int, let displayMode =  UISplitViewController.DisplayMode(rawValue: displayModeRawvalue) {
            if displayMode == .oneBesideSecondary {
                self.showCompactBottombar = true
            }else {
                self.showCompactBottombar = false
            }
        }
    }
}

//MARK: Handlers for drag and drop of drag items from other apps
extension FTShelfViewModel {
    func processCreationOfNotebooksUsingItemProviders(_ itemProviders: [NSItemProvider]){
        FTDropItemsHelper().validDroppedItems(itemProviders) { droppedItem in
            var items = [FTImportItem]();
            droppedItem.fileItems.forEach { (eachURL) in
                let tiem = FTImportItem(item: eachURL as AnyObject, onCompletion: nil);
                items.append(tiem);
            }
            droppedItem.notebookItems.forEach { (eachURL) in
                let tiem = FTImportItem(item: eachURL as AnyObject, onCompletion: nil);
                items.append(tiem);
            }
            droppedItem.imageItems.forEach { (eachURL) in
                let tiem = FTImportItem(item: eachURL, onCompletion: nil);
                items.append(tiem);
            }
            self.delegate?.beginImportingOfContentTypes(items, completionHandler: { status, shelfItems in
                
            })
        }
    }
}

//MARK: Code for shelf items fetching from backend
extension FTShelfViewModel {
    
    @MainActor
    func fetchShelfItems(animate: Bool = true) async {
        collection.shelfItems(FTUserDefaults.sortOrder()
                              , parent: groupItem
                              , searchKey: nil) { [weak self] items in
            if(animate) {
                withAnimation {
                    self?.setShelfItems(items);
                }
            }
            else {
                self?.setShelfItems(items);
            }
        }
        self.addObservers()
    }
    
    private func setShelfItems(_ items: [FTShelfItemProtocol]) {
        self.resetShelfModeTo(.normal)
        let _shelfItems = self.createShelfItemsFromData(items);
        self.shelfItems = _shelfItems
        
        self.showNoShelfItemsView = self.shelfItems.isEmpty
        
        if !shelfDidLoad {
            shelfDidLoad = true
        }
        if self.groupItem == nil { // only posting count for collection children, not when inside a group.
            NotificationCenter.default.post(name: Notification.Name(rawValue: shelfCollectionItemsCountNotification), object: nil, userInfo: ["shelfItemsCount" : self.shelfItems.count, "shelfCollectionTitle": "\(collection.displayTitle)"])
        }
    }
    
    func reloadItems(animate: Bool = true, _ onCompletion: (() -> Void)? = nil) {
        let block : (Bool, [FTShelfItemProtocol]) ->() = { [weak self] (animate,items) in
            if(animate) {
                withAnimation {
                    self?.setShelfItems(items)
                    onCompletion?();
                }
            }
            else {
                self?.setShelfItems(items)
                onCompletion?();
            }
        };
        
        self.collection.shelfItems(FTUserDefaults.sortOrder(),
                                   parent: groupItem,
                                   searchKey: nil) { [weak self ] _shelfItems in
            
            if (self?.isInHomeMode ?? false) && _shelfItems.count == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)){
                    block(animate,_shelfItems);
                }
                
            } else {
                block(animate,_shelfItems);
            }
        }
    }
}

//MARK: Nav bar options
extension FTShelfViewModel {
    func emptyTrash(){
        self.removeObserversForShelfItems()
        let deletedItems :[FTShelfItemProtocol] = self.shelfItems.compactMap({$0.model})
        self.delegate?.deleteItems(deletedItems, shouldEmptyTrash: true, onCompletion: { [weak self] _ in
            self?.addObserversForShelfItems()
            self?.resetShelfModeTo(.normal)
        })
    }
}

enum FTCurrentShelfItemState: Int {
    case shouldOpen,Opened,None
}

class FTCurrentShelfItem: Equatable {
    static func == (lhs: FTCurrentShelfItem, rhs: FTCurrentShelfItem) -> Bool {
        lhs.uuid == rhs.uuid
    }
    private var shelfItem: FTShelfItemProtocol
    
    var isQuickCreated: Bool = false

    var uuid: String {
        return self.shelfItem.uuid;
    }
    
    var shelfItemState: FTCurrentShelfItemState = .shouldOpen;
    var pin: String?
    
    init(_ shelfItem: FTShelfItemProtocol, isQuickCreated: Bool = false,isOpened: Bool = false,pin: String? = nil) {
        self.shelfItem = shelfItem
        self.isQuickCreated = isQuickCreated
        self.pin = pin
    }
}

extension FTShelfViewModel {
    func didSelectCover(_ cover: FTThemeable) {
        var selectedItems :[FTShelfItemProtocol] = []
        if mode == .selection {
            if let longpressedShelfItem = self.updateItem {
                // if long pressed item is selected, we need to perform operation considering all selected items. if long pressed item is not selected, then operation need to be performed on only long presses item ignoring selected items
                if ((self.shelfItems.first(where: {$0.id == longpressedShelfItem.model.uuid})?.isSelected) != nil) {
                    selectedItems = self.shelfItems.filter({$0.isSelected}).compactMap({$0.model})
                } else {
                    selectedItems = [longpressedShelfItem.model]
                }
            }else {
                selectedItems = self.shelfItems.filter({$0.isSelected}).compactMap({$0.model})
            }
        } else {
            if let updateItem = self.updateItem {
                selectedItems = [updateItem.model]
            }
        }
        var viewModelsToUpdate: [FTShelfItemViewModel?] = [updateItem]
        if mode == .selection {
            viewModelsToUpdate = self.shelfItems.filter({$0.isSelected})
        }
        self.delegate?.changeCoverForShelfItem(selectedItems, withTheme: cover, onCompletion: { [weak self] in
            self?.resetShelfModeTo(.normal)
            runInMainThread {
                for shelfItem in selectedItems {
                    NotificationCenter.default.post(name: NSNotification.Name.`shelfItemUpdateCover`, object: shelfItem, userInfo: nil)
                }
            }
        })
    }
}
//MARK: Tags
extension FTShelfViewModel {
    func showTagsView() {
        guard let document = shelfItemContextualMenuViewModel.shelfItem?.model as?  FTDocumentItemProtocol else {
            return
        }
        // TODO: Show Loader
        let tags = FTCacheTagsProcessor.shared.tagsForShelfItem(url: document.URL)
        let sortedArray = FTCacheTagsProcessor.shared.tagsModelForTags(tags: tags)
        displayTagsView(tags: sortedArray)
    }
    
    func displayTagsView(tags: [FTTagModel]) {
        // TODO: Dismiss Loader
        tagsForThisBook = tags
        shelfItemContextualMenuViewModel.shelfItem?.popoverType = .tags
    }
}
//MARK: Shelf Items Sort
extension FTShelfViewModel {
    var sortOption: FTShelfSortOrder {
        get {
            return FTUserDefaults.sortOrder();
        }
        set {
            if(FTUserDefaults.sortOrder() != newValue) {
                FTUserDefaults.setSortOrder(newValue);
                self.reloadItems();
            }
        }
    }
    
    var displayStlye: FTShelfDisplayStyle {
        get {
            return FTShelfDisplayStyle.displayStyle
        }
        set {
            if(newValue != FTShelfDisplayStyle.displayStyle) {
                FTShelfDisplayStyle.displayStyle = newValue;
                self.reloadItems();
            }
        }
    }
    
    func moveShelfItem(fromIndex: Int, toIndex: Int){
        let removedItem = self.shelfItems.remove(at: fromIndex)
        self.shelfItems.insert(removedItem, at: toIndex)
        self.updateSortedItemsList()
    }
    
    private func updateSortedItemsList() {
        var indexFolderItem: FTSortIndexContainerProtocol?
        if let groupItem = self.shelfItems.compactMap({$0.model}).last?.parent as? FTGroupItem {
            indexFolderItem = groupItem
        }
        else {
            indexFolderItem = self.shelfItems.compactMap({$0.model}).last?.shelfCollection as? FTSortIndexContainerProtocol
        }
        if let indexFolder = indexFolderItem {
            var booksList = [String]()
            self.shelfItems.compactMap({$0.model}).forEach { (shelfItem) in
                booksList.append(shelfItem.sortIndexHash)
            }
            indexFolder.indexCache?.updateNotebooksList(booksList, isUpdateFromCloud: false, latestUpdated: Date().timeIntervalSinceReferenceDate)
        }
    }
}

extension FTShelfViewModel: FTPaperTemplateDelegate {
    func paperTemplatePicker(_ contmroller: UIViewController, showIAPAlert feature: String?) {
        if let _feature = feature {
            FTIAPurchaseHelper.shared.showIAPAlertForFeature(feature: _feature, on: contmroller)
        }
        else {
            FTIAPurchaseHelper.shared.showIAPAlert(on: contmroller);
        }
    }
    

    func didSelectDigitalDiary(fileName: String, title: String, startDate: Date, endDate: Date, coverImage: UIImage, isLandScape: Bool) {
        let stockFolder = "StockPapers";
        let url1 = Bundle.main.url(forResource: stockFolder, withExtension: "bundle")!;
        let subFiles = try? FileManager.default.contentsOfDirectory(at: url1, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        let planner = subFiles?.filter { $0.lastPathComponent == "\(fileName).nsp" }
        if let plannerUrl = planner?.first {
            if let theme = FTTheme.theme(url: plannerUrl, themeType: .papers) as? FTAutoTemlpateDiaryTheme {
                theme.startDate = startDate
                theme.endDate = endDate

                var varients = FTBasicTemplatesDataSource.shared.getDefaultVariants()
                varients.isLandscape = isLandScape
                (theme as FTPaperTheme).setPaperVariants(varients)
//                self.didSelectPaperTheme(theme: theme)
            }
        }
    }

    func didSelectTemplate(info: FTTemplatesStore.FTTemplateInfo) {
        if let fileUrl = info.url {
            let theme = FTStoreTemplatePaperTheme(url: fileUrl)
            theme.isCustom = info.isCustom
            self.didSelectStoreTemplateTheme(theme, isLandscape: info.isLandscape,isDarkTemplate: info.isDark)
        }
    }
    private func didSelectStoreTemplateTheme(_ theme:FTTheme,isLandscape: Bool,isDarkTemplate:Bool){
        let currentDevice = FTDeviceDataManager().getCurrentDevice()
        let templateSizeModel = FTTemplateSizeModel(size: currentDevice.displayName, portraitSize: currentDevice.dimension_port, landscapeSize: currentDevice.dimension_land)
        let basicTemplatesDataSource = FTBasicTemplatesDataSource.shared
        let templateColor = FTTemplateColorModel(color: .custom, hex: isDarkTemplate ? UIColor(hexString: "#1D232F").hexStringFromColor() : UIColor.white.hexStringFromColor())
        let selectedPaperVariantsAndTheme =
        FTSelectedPaperVariantsAndTheme(templateColorModel:templateColor,
                                        lineHeight: basicTemplatesDataSource.getSavedLineHeightForMode(.quickCreate),
                                        orientation: isLandscape ? FTTemplateOrientation.landscape : FTTemplateOrientation.portrait,
                                        size: templateSizeModel.size,
                                        selectedPaperTheme: theme)
        self.udpatePaperThemeAndVariants(selectedPaperVariantsAndTheme)
    }
    func didSelectPaperTheme(theme: FTNewNotebook.FTSelectedPaperVariantsAndTheme) {
        udpatePaperThemeAndVariants(theme)
    }

    private func udpatePaperThemeAndVariants(_ themeWithVariants: FTNewNotebook.FTSelectedPaperVariantsAndTheme) {
        let basicTemplatesDataSource = FTBasicTemplatesDataSource.shared
        basicTemplatesDataSource.saveThemeWithVariants(themeWithVariants,mode: .quickCreate)
    }
}


extension FTShelfViewModel {
    func itemProvider(_ shelfItem: FTShelfItemViewModel) -> NSItemProvider {
        self.currentDraggedItem = shelfItem
        FTShelfDraggedItemProvider.shared.draggedNotebook = shelfItem.model
        let userActivityID: String;
        if shelfItem.model is FTDocumentItemProtocol {
            userActivityID = FTNoteshelfSessionID.openNotebook.activityIdentifier;
        }
        else {
            userActivityID = FTNoteshelfSessionID.openGroup.activityIdentifier;
        }
        let userActivity = NSUserActivity(activityType: userActivityID)
        let itemProvider = NSItemProvider(object: shelfItem)
        itemProvider.registerObject(userActivity, visibility: .all)
        return itemProvider
    }

    func hasNS2BookItemAmongSelectedShelfItems(_ shelfItems: [FTShelfItemViewModel]) -> Bool {
        return (shelfItems.first(where: {$0.model.URL.isNS2Book}) != nil)
    }

    func hasAGroupShelfItemAmongSelectedShelfItems(_ shelfItems: [FTShelfItemViewModel]) -> Bool {
        return (shelfItems.first(where: {$0 is FTGroupItemViewModel}) != nil)
    }
}
