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
    func openGetInspiredPDF(_ url: URL,title: String);
    func openDiscoveryItemsURL(_ url:URL?)
    func recordingViewController(_ recordingsViewController: FTWatchRecordedListViewController, didSelectRecording recordedAudio:FTWatchRecordedAudio, forAction actionType:FTAudioActionType);
    func canProcessNotification() -> Bool

}
protocol FTShelfCompactViewModelProtocol: AnyObject {
    func didChangeSelectMode(_ mode: FTShelfMode)
}
class FTShelfViewModel: NSObject, ObservableObject {
    
    struct ShelfReloadState {
        var isReloadInProgress: Bool = false
        var scheduleReload: Bool = false
    }

    var isReady = false;
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
    private var closedDocumentItem: FTDocumentItem?
    private var shelfReloadState = ShelfReloadState()

    weak var groupViewOpenDelegate: FTShelfViewDelegate?
    var didTapOnSeeAllNotes: (() -> Void)?
    @Published var scrollToItemID: String?
    // MARK: Published variables
    @Published var mode: FTShelfMode = .normal {
        didSet {
            addOrRemoveObserversBasedOnMode()
        }
    }

    @Published var shelfItems: [FTShelfItemViewModel] = []
    {
        didSet {
            if(isInHomeMode && shelfItems.count != oldValue.count) {
                if self.groupItem == nil { // only posting count for collection children, not when inside a group.
                    NotificationCenter.default.post(name: Notification.Name(rawValue: shelfCollectionItemsCountNotification), object: nil, userInfo: ["shelfItemsCount" : shelfItems.count, "shelfCollectionTitle": "\(collection.displayTitle)"])
                }
            }
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
    @Published var tagsForThisBook: [FTTagItemModel] = []
    @Published var allowHitTesting: Bool = true
    @Published var showCompactBottombar: Bool = false
    @Published var showNotebookModifiedDate: Bool = UserDefaults.standard.bool(forKey: "Shelf_ShowDate")
    @Published var orientation = UIDevice.current.orientation
    @Published var isSidebarOpen: Bool = true
    @Published var shouldShowGetStartedInfo: Bool = false //FTUserDefaults.isFirstLaunch()
    @Published var selectedShelfItems: [FTShelfItemViewModel] = []

    // MARK: Normal Variables
    var collection: FTShelfItemCollection {
        didSet {
            reset()
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
    var displayStlye: FTShelfDisplayStyle = .Gallery
    private var observer: NSKeyValueObservation?
    private var shelfRefreshTimer = FTShelfRefreshTimer();

    init(collection: FTShelfItemCollection, groupItem: FTGroupItemProtocol? = nil) {
        self.collection = collection
        self.groupItem = groupItem
        super.init()
        subscribeToShelfItemChanges()
        toolbarViewModel.delegate = self
        self.addContextualMenuOerationsObserver()
        self.configAndObserveDisplayStyle()
    }
    
    init(sidebarItemType: FTSideBarItemType){
        isInHomeMode = true
        self.collection = FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection
        super.init()
        subscribeToShelfItemChanges()
        toolbarViewModel.delegate = self
        self.addContextualMenuOerationsObserver()
        self.configAndObserveDisplayStyle()
    }
    
    private func configAndObserveDisplayStyle() {
        self.displayStlye = FTShelfDisplayStyle(rawValue: UserDefaults.standard.shelfDisplayStyle) ?? .Icon;
        observer = UserDefaults.standard.observe(\.shelfDisplayStyle, options: [.new]) { [weak self] (userDefaults, change) in
            guard let self else { return }
            let value = userDefaults.shelfDisplayStyle
            if value != self.displayStlye.rawValue {
                self.displayStlye = FTShelfDisplayStyle(rawValue: value) ?? .Gallery
                self.reloadShelf()
            }
        }
    }

    // MARK: Computed variables
    var areAllItemsSelected: Bool {
        selectedShelfItems.count == shelfItems.count
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
                let selectedCount = self.selectedShelfItems.count
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
        return !(collection.isStarred || collection.isTrash)
    }
    var canShowStarredIconOnNB: Bool {
        return !(collection.isTrash)
    }
    var supportsDragAndDrop: Bool {
        !(collection.isAllNotesShelfItemCollection || collection.isStarred || collection.isTrash)
    }
    var supportsDrop: Bool {
        (isInHomeMode || !(collection.isStarred || collection.isTrash))
    }
    var disableBottomBarItems: Bool {
        self.selectedShelfItems.isEmpty
    }

    var selectedDocItems: [FTShelfItemProtocol] {
        var selectedItems =  self.selectedShelfItems.compactMap({$0.model})
        if selectedItems.count == 0, let selectedItemUsingContexualMenu = self.updateItem?.model {
            selectedItems = [selectedItemUsingContexualMenu]
        }
        return selectedItems
    }

    // MARK: Mutating functions
    func selectAllItems() {
        self.selectedShelfItems = self.shelfItems
    }
    
    func deselectAllItems() {
        self.selectedShelfItems = []
    }
    
    func finalizeShelfItemsEdit() {
        self.selectedShelfItems = []
    }
    func subscribeToShelfItemChanges(){
        self.cancellables.removeAll()
        self.shelfItems.forEach({ [weak self] in
            let item = $0.$coverImage.removeDuplicates().dropFirst().sink(receiveValue: { value in
                self?.objectWillChange.send()
            })
            self?.cancellables.append(item)
        })
    }

    func getShelfItemWithUUID(_ uuid: String) -> FTShelfItemViewModel? {
        self.shelfItems.first(where: {$0.model.uuid == uuid})
    }
    
    deinit {
        shelfRefreshTimer.reset()
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
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.sortIndexPlistUpdated, object: nil)
    }
    
    func addObserversForShelfItems(){
        if isObserversAdded {
            return
        }
        self.addObservers()
    }
    
    func reloadShelf(animate: Bool = true) {
        shelfRefreshTimer.reset()
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
        shelfRefreshTimer.reset()
        self.removeObserversForShelfItems()
    }
    
    func shelfViewDidMovedToFront(with item : FTDocumentItem) {
        self.closedDocumentItem = item
        self.addObserversForShelfItems()
        self.reloadShelf(animate: false);
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
    func updateGetStartedInfoWithDelay(){
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateShowingGetStartedInfoStatus), object: nil)
        self.perform(#selector(updateShowingGetStartedInfoStatus), with: nil, afterDelay: 0.7)
    }

    @objc func updateShowingGetStartedInfoStatus() {
        if isInHomeMode {
            withAnimation {
                if shelfItems.count > 0 {
                    FTUserDefaults.setFirstLaunch(false)
                    self.shouldShowGetStartedInfo = false
                } else {
                    if !FTUserDefaults.isFirstLaunch() {
                        FTUserDefaults.setFirstLaunch(true)
                        self.shouldShowGetStartedInfo = false
                    }
                }
            }
        } else {
            if shelfItems.count > 0 {
                FTUserDefaults.setFirstLaunch(false)
                self.shouldShowGetStartedInfo = false
            }
        }
    }

    func addContextualMenuOerationsObserver(){
        self.shelfItemContextualMenuViewModel.$performAction
            .dropFirst()
            .sink { [weak self] option in
                guard let self = self else { return }
                if let option = option {
                    self.performContexualMenuOperation(option)
                }
            }
            .store(in: &cancellables1)
    }

    @objc func handleShowDateStatusChange() {
        self.showNotebookModifiedDate = UserDefaults.standard.bool(forKey: "Shelf_ShowDate")
    }

    func addObservers() {
        if(isObserversAdded || !self.isReady) {
            return;
        }
        isObserversAdded = true;
        NotificationCenter.default.addObserver(self, selector: #selector(shelfItemDidGetAdded(_:)), name: NSNotification.Name.shelfItemAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shelfItemDidGetRemoved(_:)), name: NSNotification.Name.shelfItemRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shelfitemDidgetUpdated(_:)), name: NSNotification.Name.shelfItemUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(groupitemDidgetAdded(_:)), name: NSNotification.Name.groupItemAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(groupitemDidgetRemoved(_:)), name: NSNotification.Name.groupItemRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shelfItemDropOperationFinished(_:)), name: NSNotification.Name("ShelfItemDropOperationFinished"), object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(splitDisplayChangeHandler(_:)) , name: NSNotification.Name("SplitDisplayModeChangeNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleShowDateStatusChange), name: Notification.Name(rawValue: FTShelfShowDateChangeNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shelfSortIndexUpdated(_:)), name: NSNotification.Name.sortIndexPlistUpdated, object: nil)
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
    
    func fetchShelfItems(animate: Bool = true)  {
        collection.shelfItems(FTUserDefaults.sortOrder()
                              , parent: groupItem
                              , searchKey: nil) { [weak self] items in
            guard let self = self else {
                return
            }
            self.setShelfItems(items,animate:animate);
            if let item = self.closedDocumentItem {
                self.scrollToItemID = item.uuid
                self.closedDocumentItem = nil
            }
            self.isReady = true;
            self.addObservers()
        }
    }
    
    private func setShelfItems(_ items: [FTShelfItemProtocol],animate:Bool) {
        self.resetShelfModeTo(.normal)
        let _shelfItems = self.createShelfItemsFromData(items);
        if(animate) {
            withAnimation {
                self.shelfItems = _shelfItems
            }
        }
        else {
            self.shelfItems = _shelfItems
        }

        self.showNoShelfItemsView = self.shelfItems.isEmpty

        if !self.shelfDidLoad {
            self.shelfDidLoad = true
        }
        if self.groupItem == nil { // only posting count for collection children, not when inside a group.
            NotificationCenter.default.post(name: Notification.Name(rawValue: shelfCollectionItemsCountNotification), object: nil, userInfo: ["shelfItemsCount" : self.shelfItems.count, "shelfCollectionTitle": "\(self.collection.displayTitle)"])
        }
    }

    @objc func reloadItems(force: Bool) {
        guard self.isReady else {
            return;
        }
        guard shelfReloadState.isReloadInProgress == false else {
            shelfReloadState.scheduleReload = true
            return
        }
        let curDate = Date.timeIntervalSinceReferenceDate;
        if !force, curDate - shelfRefreshTimer.lastRenderTime  <= shelfRefreshTimer.refreshDuration {
            shelfRefreshTimer.scheduleReload({
                self.reloadItems(force: true);
            });
            return;
        }
        
        shelfRefreshTimer.cancelScheduledReload();
        shelfRefreshTimer.setLastRenderedTime(force ? 0 : curDate)
        
        shelfReloadState.isReloadInProgress = true
        reloadShelfItems(animate: true, { [weak self] in
            guard let self = self else { return }
            self.shelfReloadState.isReloadInProgress = false
            if shelfReloadState.scheduleReload {
                shelfReloadState.scheduleReload = false
                shelfRefreshTimer.setLastRenderedTime(Date.timeIntervalSinceReferenceDate - (shelfRefreshTimer.refreshDuration + 0.1))
                self.reloadItems(force: false)
            }
        })
    }
    
    func reloadShelfItems(animate: Bool, _ onCompletion: (() -> Void)?) {
        guard self.isReady else {
            onCompletion?()
            return;
        }
        self.collection.shelfItems(FTUserDefaults.sortOrder(),
                                   parent: groupItem,
                                   searchKey: nil) { [weak self ] _shelfItems in
            guard let self = self else { return }
            self.setShelfItems(_shelfItems, animate: animate);
            onCompletion?()
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
                if !(self.selectedShelfItems.isEmpty) {
                    selectedItems = self.selectedShelfItems.compactMap({$0.model})
                } else {
                    selectedItems = [longpressedShelfItem.model]
                }
            }else {
                selectedItems = self.selectedShelfItems.compactMap({$0.model})
            }
        } else {
            if let updateItem = self.updateItem {
                selectedItems = [updateItem.model]
            }
        }
        var viewModelsToUpdate: [FTShelfItemViewModel?] = [updateItem]
        if mode == .selection {
            viewModelsToUpdate = self.selectedShelfItems
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
        if let docUUID = document.documentUUID {
            let tags = FTCacheTagsProcessor.shared.documentTagsFor(documentUUID: docUUID)
            let tagItems = FTTagsProvider.shared.getAllTagItemsFor(tags)
            displayTagsView(tags: tagItems)
        }
    }

    func displayTagsView(tags: [FTTagItemModel]) {
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
                self.reloadItems(force: true);
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

    func hasAGroupShelfItemAmongSelectedShelfItems(_ shelfItems: [FTShelfItemViewModel]) -> Bool {
        return (shelfItems.first(where: {$0 is FTGroupItemViewModel}) != nil)
    }
}
//MARK: Tap actions of notebook and group
extension FTShelfViewModel {
    func didTapOnShelfItem(_ shelfItem: FTShelfItemViewModel){
        if(mode == .selection) {
            if selectedShelfItems.contains(shelfItem) {
                selectedShelfItems.removeAll(where: { $0.id == shelfItem.id })
            } else {
                self.selectedShelfItems.append(shelfItem)
            }
            // Track Event
            track(EventName.shelf_select_book_tap, params: [EventParameterKey.location: shelfLocation()], screenName: ScreenName.shelf)
        }
        else {
            openShelfItem(shelfItem, animate: true, isQuickCreatedBook: false)
            track(EventName.shelf_book_tap, params: [EventParameterKey.location: shelfLocation()], screenName: ScreenName.shelf)
        }
    }
    func didTapGroupItem(_ groupItem: FTGroupItemViewModel){
        if(self.mode == .selection) {
            if selectedShelfItems.contains(groupItem) {
                selectedShelfItems.removeAll(where: { $0.id == groupItem.id })
            } else {
                self.selectedShelfItems.append(groupItem)
            }
            // Track Event
            track(EventName.shelf_select_group_tap, params: [EventParameterKey.location: shelfLocation()], screenName: ScreenName.shelf)
        }
        else {
            self.delegate?.setLastOpenedGroup(groupItem.model.URL)
            self.groupViewOpenDelegate?.didTapOnShelfItem(groupItem.model);
            // Track Event
            track(EventName.shelf_group_tap, params: [EventParameterKey.location: shelfLocation()], screenName: ScreenName.shelf)
        }
    }
}

private class FTShelfRefreshTimer: NSObject {
    private(set) var isRefreshSceduled = false;
    private(set) var lastRenderTime = Date.timeIntervalSinceReferenceDate;
    let refreshDuration: TimeInterval = 0.3;
    private var scheduledFunction: (()->())?;
    
    func setLastRenderedTime(_ timeInterval: TimeInterval) {
        self.lastRenderTime = timeInterval;
    }
    
    func setisRefreshSceduled(_ scheduled: Bool) {
        isRefreshSceduled = scheduled;
    }
}

private extension FTShelfRefreshTimer {
    @objc func scheduleReload(_ scheduledFunction: (()->())?) {
        if !isRefreshSceduled {
            self.scheduledFunction = scheduledFunction;
            isRefreshSceduled = true
            self.perform(#selector(self.triggerReloadAction), with: nil, afterDelay: self.refreshDuration);
        }
    }
    
    @objc private func triggerReloadAction() {
        self.isRefreshSceduled = false;
        self.scheduledFunction?();
        self.scheduledFunction = nil;
    }
    
    @objc func cancelScheduledReload() {
        self.isRefreshSceduled = false;
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.triggerReloadAction), object: nil);
    }
    
    func reset() {
        self.cancelScheduledReload();
        self.lastRenderTime = 0;
    }
}
