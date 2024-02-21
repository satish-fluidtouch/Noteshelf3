//
//  FTSidebarViewModel.swift
//  Noteshelf3
//
//  Created by Akshay on 05/05/22.
//

import Combine
import SwiftUI
import FTCommon

let shelfCollectionItemsCountNotification = "FTShelfCollectionChildrenCountNotification"

extension NSNotification.Name {
    static let categoryItemsDidUpdateNotification = NSNotification.Name(rawValue: "FTCategoryItemsDidUpdateNotification")
    static let refresSideMenuNotification = NSNotification.Name(rawValue: "refreshSideMenu")
    static let didChangeUnfiledCategoryLocation = Notification.Name(rawValue: "didChangeUnfiledCategoryLocation");
}

protocol FTCategoryDropDelegate: AnyObject {
    func moveDraggedShelfItem(_ item : FTShelfItemProtocol,
                              toCollection collection: FTShelfItemCollection,
                              onCompletion: @escaping (NSError?, [FTShelfItemProtocol]) -> Void)
    func favoriteShelfItem(_ item: FTShelfItemProtocol, toPin: Bool)
    func endDragAndDropOperation()
}

class FTSidebarViewModel: NSObject, ObservableObject {
    //MARK: Delegates
    weak var delegate: FTSidebarViewDelegate?
    weak var dropDelegate: FTCategoryDropDelegate?

    //MARK: Published variables
    @Published var currentDraggedSidebarItem: FTSideBarItem?
    @Published var fadeDraggedSidebarItem: FTSideBarItem?
    @Published var selectedSideBarItem: FTSideBarItem? {
        didSet {
            selectedSideBarItemType = selectedSideBarItem?.type ?? .home
        }
    }
    @Published var highlightItem: FTSideBarItem?
    @Published var menuItems: [FTSidebarSection] = [] {
        didSet {
             addObservers()
        }
    }
    
    //MARK: Private variables
    private(set) var sidebarItemContexualMenuVM: FTSidebarItemContextualMenuVM = FTSidebarItemContextualMenuVM()
    private var newCollectionAddedOrUpdated: Bool = false
    private var cancellables = [AnyCancellable]()
    private var selectedSideBarItemType: FTSideBarItemType = .home
    private var lastSelectedTag: String = ""

    var activeReorderingSidebarSectionType: FTSidebarSectionType?

    var currentSideBarDropItem: FTSideBarItem?
    var allowableSidebarSectionsInPhone: [FTSidebarSectionType] = [.all,.categories,.media,.tags]
    var sideBarItemWidth: CGFloat = 280

    //MARK: Computed variables
    lazy var newItem: FTSideBarItem = {
        return FTSideBarItemNewCategory.newInstance()
    }()
    
   weak var selectedShelfItemCollection: FTShelfItemCollection? {
       didSet {
           updateCurrentSidebarItemCollection()
       }
    }
    init(collection: FTShelfItemCollection? = nil) {
        super.init()
        self.setSidebarItemTypeForCollection(collection)
        self.selectedShelfItemCollection = collection
        self.commonInitiaize()
    }
    init(selectedSideBarItemType: FTSideBarItemType, selectedTag:String = "") {
        super.init()
        self.selectedSideBarItemType = selectedSideBarItemType
        if selectedSideBarItemType == .home {
            selectedShelfItemCollection = FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection
        }
        self.lastSelectedTag = selectedTag
        self.commonInitiaize()
    }
    deinit {
    }

    private func commonInitiaize() {
        self.addObserverForContextualOperations();
        self.fetchSidebarMenuItems()
    }
    
    func shouldShowNumberOfNotebooksCountFor(item: FTSideBarItem) -> Bool {
        if let selectedSideBarItem = selectedSideBarItem, selectedSideBarItem.id == item.id, item.type != .templates {
            return true
        }
        return false
    }
    func getRowSelectionColorFor(item: FTSideBarItem) -> Color {
        var color = Color.appColor(.sidebarBG)
        if let highlightedItem = highlightItem, highlightedItem.id == item.id, fadeDraggedSidebarItem == nil { // For fadding when any book/group is going to drop on a category
                color = item.highlightColor
        }
        else if let selectedSideBarItem = selectedSideBarItem, selectedSideBarItem.id == item.id {
            if fadeDraggedSidebarItem == item { // when draggable sidebar item is moving
                color = Color.appColor(.sidebarBG)
            }else if selectedSideBarItem.id == item.id { // For current selected side bar item
                color = item.highlightColor
            }
        } else if item.type == .category || item.type == .unCategorized {
            if let itemColl = item.shelfCollection, let selectedColl = selectedSideBarItem?.shelfCollection, itemColl.uuid == selectedColl.uuid, itemColl.uuid != fadeDraggedSidebarItem?.shelfCollection?.uuid{
                color = item.highlightColor
            }
        }
        return color
    }
    func getRowForegroundColorFor(item: FTSideBarItem) -> Color {
        var color = Color.appColor(.black1)
        if let highlightedItem = highlightItem, highlightedItem.id == item.id, fadeDraggedSidebarItem == nil { // For fadding when any book/group is going to drop on a category
            color = Color.appColor(.black1)
        }
        else if let selectedSideBarItem = selectedSideBarItem {
            if fadeDraggedSidebarItem == item { // when draggable sidebar item is moving
                color = Color.appColor(.black1)
            } else if selectedSideBarItem.id == item.id { // For current selected side bar item
                color = .white
            }
        }else if item.type == .category || item.type == .unCategorized {
            if let itemColl = item.shelfCollection, let selectedColl = selectedSideBarItem?.shelfCollection, itemColl.uuid == selectedColl.uuid,selectedColl.uuid != fadeDraggedSidebarItem?.shelfCollection?.uuid {
                color = Color.appColor(.white100)
            }
        }
        return color
    }
    func finalizeHighlightOfAllItems() {
        for index in 0..<menuItems.count {
            menuItems[index].finaliseHightlight()
        }
    }
    func finalizeEditOfAllSections() {
        for index in 0..<menuItems.count {
            menuItems[index].finaliseEdit()
        }
    }
    func endEditingActions(){ // ending editing of sidebar items if any
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    func sidebarItemOfType(_ type: FTSideBarItemType) -> FTSideBarItem {
        guard let matchedItem = self.menuItems.flatMap({$0.items}).first(where: {$0.type == type}) else {
            debugLog("⚠️ Unable to find the passed item \(type.displayTitle) falling back to all notes")
            return FTSideBarItem(shelfCollection: FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection)
        }
        return matchedItem
    }

    func selectSidebarItemWithCollection(_ shelfItemCollection: FTShelfItemCollection){
        setSideBarItemSelection()
    }
    func showSidebarItemWithCollection(_ shelfItemCollection: FTShelfItemCollection){
        selectedSideBarItem = menuItems.flatMap({$0.items})
            .first(where: {$0.shelfCollection?.uuid == selectedShelfItemCollection?.uuid})
        setSideBarItemSelection()
        if let selectedSideBarItem {
            self.delegate?.didTapOnSidebarItem(selectedSideBarItem)
        }
    }
    
    func addNotificationObservers() {
        self.menuItems.forEach { eachItem in
            eachItem.addObservers();
            eachItem.fetchItems();
        }
    }
    
    func removeNotificationObservers() {
        self.menuItems.forEach { eachItem in
            eachItem.removeObservers();
        }
    }
}
private extension FTSidebarViewModel {
    func updateCurrentSidebarItemCollection(){
        let collectionTypes: [FTSideBarItemType] = [.home,.starred,.unCategorized,.trash,.category]
        if collectionTypes.contains(where: {$0 == selectedSideBarItem?.type}) {
            if selectedSideBarItem != nil,
               selectedSideBarItem?.shelfCollection != nil,
               selectedSideBarItem?.shelfCollection?.displayTitle == selectedShelfItemCollection?.displayTitle,selectedSideBarItem?.shelfCollection?.uuid != selectedShelfItemCollection?.uuid {
                selectedSideBarItem?.setShelfCollection(selectedShelfItemCollection);
//                selectedSideBarItem?.shelfCollection = selectedShelfItemCollection
            }
        }
    }
    func setSidebarItemTypeForCollection(_ collection: FTShelfItemCollection?){
        if let collection {
            if collection.isStarred {
                selectedSideBarItemType = .starred
            } else if collection.isTrash {
                selectedSideBarItemType = .trash
            } else if collection.isUnfiledNotesShelfItemCollection {
                selectedSideBarItemType = .unCategorized
            } else {
                selectedSideBarItemType = .category
            }
        }
    }
    func addObserverForContextualOperations(){
        self.sidebarItemContexualMenuVM.$performAction
            .dropFirst()
            .sink { [weak self] option in
                guard let self = self else { return }
                print("choosen option",option?.displayTitle ?? "")
                if let option = option {
                    self.performContexualMenuOperation(option)
                }
            }
            .store(in: &cancellables)
    }

    func addObservers() {
        self.menuItems.forEach({ menuItem in
//            menuItem.$isExpanded.sink { isExpanded in
//                self.objectWillChange.send()
//            }.store(in: &cancellables)
            
//            menuItem.$items.sink { [weak self] items in
//                self?.setSideBarItemSelection()
//                self?.objectWillChange.send()
//            }.store(in: &cancellables)
        })
    }

    func isGroup(_ fileURL: Foundation.URL) -> Bool {
        let fileItemURL = fileURL.urlByDeleteingPrivate();
        if(fileItemURL.pathExtension == FTFileExtension.group) {
            return true;
        }
        return false;
    }
}
//MARK: Side bar item operations
extension FTSidebarViewModel {
    func deleteSideBarItem(_ item: FTSideBarItem){
        if item.type == .category{
            self.deleteCategory(item)
        } else if item.type == .tag {
            self.deleteTag(item)
        }
    }
    func renameSideBarItem(_ item: FTSideBarItem, newTitle:String) {
        if item.type == .tag {
            self.renametag(item, newTitle: newTitle)
        } else if item.type == .category {
            self.renameCategory(item,newTitle: newTitle)
        }
    }
    
    func emptyTrash(_ sideBarItem: FTSideBarItem){
        if let trashShelfItemCollection = sideBarItem.shelfCollection {
            self.delegate?.emptyTrash(trashShelfItemCollection, showConfirmationAlert: false, onCompletion: { status in

            })
        }
    }
    func moveDraggedShelfItemWithPath(_ path: String, collectionName: String){
        print("Shelf Item path", path)
        var shelfItem: FTShelfItemProtocol?;
        let shelfItemURL = URL(fileURLWithPath: path)
        let relativePath = shelfItemURL.relativePathWRTCollection()
        func endHighlightingSideBarItem() {
            runInMainThread {
                self.highlightItem = nil
                self.dropDelegate?.endDragAndDropOperation()
            }
        }

        // As the main function is called in serial queue and below operation to be called on main thread
        func favoriteShelfItem() {
            runInMainThread {
                if let item = shelfItem as? FTDocumentItemProtocol, item.isDownloaded {
                    self.dropDelegate?.favoriteShelfItem(item, toPin: true)
                }
            }
        }

        if let shelfCollection = highlightItem?.shelfCollection {
            FTNoteshelfDocumentProvider.shared.shelfCollection(title: collectionName) { shelfCollection in
                if let shelfCollection = shelfCollection {
                    if(self.isGroup(shelfItemURL)) {
                        shelfItem = shelfCollection.groupItemForURL(shelfItemURL)
                    }else {
                        var groupItem : FTGroupItemProtocol?;
                        if let groupPath = relativePath.relativeGroupPathFromCollection() {
                            let url = shelfCollection.URL.appendingPathComponent(groupPath);
                            groupItem = shelfCollection.groupItemForURL(url);
                        }
                        shelfItem = shelfCollection.documentItemWithName(title: relativePath.documentName(), inGroup: groupItem)
                    }
                }
            }
            if let shelfItem = shelfItem {
                if shelfCollection.isStarred {
                    if FTRecentEntries.isFavorited(shelfItem.URL){
                        // show toast as its already favorited
                        endHighlightingSideBarItem()
                    }else {
                        if shelfItem is FTGroupItemProtocol {
                            // show toast as group cannot be favorited
                        }else {
                            favoriteShelfItem()
                        }
                        endHighlightingSideBarItem()
                    }
                } else {
                    dropDelegate?.moveDraggedShelfItem(shelfItem, toCollection: shelfCollection, onCompletion: { (error, shelfItems) in
                        if error == nil {
                            endHighlightingSideBarItem()
                        }
                    })
                }
            } else {
                endHighlightingSideBarItem()
            }
        }
    }
    func addNewCategoryWithTitle(_ title: String) {
        var title = title
        if title.isEmpty {
            title = NSLocalizedString("Untitled", comment: "Untitle");
        }
        FTNoteshelfDocumentProvider.shared.createShelf(title) { [weak self ](error, collection) in
            if let _ = error {
            }
            else if let shelfCollection = collection {
                self?.selectedShelfItemCollection = shelfCollection
                self?.newCollectionAddedOrUpdated = true
                let section = self?.section(type: .categories);
                section?.addItem(FTSideBarItem(shelfCollection: shelfCollection));
                self?.setSideBarItemSelection();
            }
        }
    }
    
    func renameCategory(_ category:FTSideBarItem,newTitle: String){
        guard let shelfCollection = category.shelfCollection else {
            return
        }
        let trashCategoryTitle = NSLocalizedString("Trash", comment: "Trash");
        guard newTitle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != trashCategoryTitle.lowercased() else {
            return;
        }
        if newTitle != shelfCollection.displayTitle {
            FTNoteshelfDocumentProvider.shared.renameShelf(shelfCollection, title: newTitle) { [weak self](error,shelfCollection) in
                if let _ = error {
                } else if let shelfCollection = shelfCollection, self?.selectedShelfItemCollection?.uuid == shelfCollection.uuid {
                    self?.selectedShelfItemCollection = shelfCollection
                    self?.delegate?.didSidebarItemRenamed(category)
                }
            }
        }
    }
    func deleteCategory(_ category: FTSideBarItem){
        guard let shelfCollection = category.shelfCollection else {
            return
        }
        let currentSelectedCategpory = self.selectedSideBarItem?.shelfCollection
        FTNoteshelfDocumentProvider.shared.moveShelfToTrash(shelfCollection, onCompletion: { [weak self](error, deletedCollection) in
            //self.delegate?.shelfCategory(self, didDeleteCollection: deletedCollection!);
            let categoriesSection = self?.section(type: .categories)
            if let deletedCategoryIndex = categoriesSection?.items.firstIndex(where: {$0.id == category.id}) {
                categoriesSection?.removeItem(at: deletedCategoryIndex);
                let sideBarItemTobeSelected: FTShelfItemCollection!
                if category.id == currentSelectedCategpory?.uuid {//If current category is being deleted
                        if let totalCategories = categoriesSection?.items.count, totalCategories > 0 {
                            if deletedCategoryIndex == totalCategories, let lastCategory = categoriesSection?.items.last?.shelfCollection {//Choose last category if it was last
                                sideBarItemTobeSelected = lastCategory
                            }
                            else {//Choose a category with same index
                                sideBarItemTobeSelected = categoriesSection?.items[deletedCategoryIndex].shelfCollection;
                            }
                        }
                        else {
                            sideBarItemTobeSelected = self?.menuItems.first?.items.first?.shelfCollection // pointing to all notes incase of no categories
                        }
                }
                else {
                    sideBarItemTobeSelected = currentSelectedCategpory;
                }
                self?.newCollectionAddedOrUpdated = true
                self?.selectedShelfItemCollection = sideBarItemTobeSelected
                self?.setSideBarItemSelection();
            }
        })
    }
    func openSideBarItemInNewWindow(_ item: FTSideBarItem){
        if item.type == .starred ||
            item.type == .unCategorized ||
            item.type == .category {
            guard let shelfCollection = item.shelfCollection else {
                return
            }
            self.openItemInNewWindow(shelfCollection, pageIndex: nil)
        } else if item.type == .home ||
                    item.type == .media ||
                    item.type == .audio ||
                    item.type == .bookmark ||
                    item.type == .templates {
            self.openContentItemInNewWindow(item.type)
        } else if item.type == .tag {
            self.openTagItemInNewWindow(selectedTag: item.title)
        }
    }
}
//MARK: Menu options fetching and building
extension FTSidebarViewModel {
    func updateUserCreatedCategories() {
        self.section(type: .categories).fetchItems();
    }
    
    private func fetchSidebarMenuItems() {
        self.buildSideMenuItems()
    }

    private func buildSideMenuItems(){
        FTSidebarManager.copyBundleDataIfNeeded()
        let sideBarDict = FTSidebarManager.getSideBarData()
        if let sideBarStatucDict = sideBarDict["SideBarStatus"] as? [String: Bool] {
            FTUserDefaults.defaults().register(defaults: sideBarStatucDict);
        }
        
        self.menuItems.append(FTSidebarSectionSystem());
        self.menuItems.append(FTSidebarSectionUserShelfs())
        self.menuItems.append(FTSidebarSectionMedia());
        self.menuItems.append(FTSidebarSectionTags());
        self.setSideBarItemSelection()
    }
    
    func setSideBarItemSelection(){
        let nonCollectionTypes: [FTSideBarItemType] = [.templates,.media,.bookmark,.audio]
        if selectedSideBarItemType == .tag || selectedSideBarItemType == .allTags {
            if let selectedSideBarItem = self.selectedSideBarItem {
                let selectedItem = menuItems.compactMap( { $0.items.first(where:{ $0.id == selectedSideBarItem.id })}).first
                if selectedItem != nil {
                    self.selectedSideBarItem = selectedItem
                } else if let selectedSideBarItem = menuItems.compactMap( { $0.items.first(where:{ $0.title == "sidebar.allTags".localized })}).first {
                    self.selectedSideBarItem = selectedSideBarItem
                    self.delegate?.didTapOnSidebarItem(selectedSideBarItem)
                }
            } else if let selectedSideBarItem = menuItems.compactMap({$0.items.first(where:{$0.type == selectedSideBarItemType && $0.title.lowercased() == lastSelectedTag.lowercased()})}).first {
                self.selectedSideBarItem = selectedSideBarItem
            }
        } else if nonCollectionTypes.contains(where: { $0 == selectedSideBarItemType}) {
            let selectedSideBarItem = menuItems.compactMap({$0.items.first(where:{$0.type == selectedSideBarItemType})}).first
            self.selectedSideBarItem = selectedSideBarItem
        }
        else if let collection = selectedShelfItemCollection {
            selectedSideBarItem = menuItems.flatMap({$0.items})
                .first(where: {$0.shelfCollection?.uuid == collection.uuid})
        }
        if newCollectionAddedOrUpdated,let selectedSideBarItem {
            newCollectionAddedOrUpdated = false
            self.delegate?.didTapOnSidebarItem(selectedSideBarItem)
        }
    }
}

//MARK: Sidebar Sections open/close status maintainance And Categories/Tags user defined order maintainance logic
extension FTSidebarViewModel {
    func moveItemInCategory(_ sectionType: FTSidebarSectionType,fromOrder: Int, toOrder: Int) {
        _ = self.section(type: sectionType).moveItem(fromOrder: fromOrder, toOrder: toOrder);
    }
}

class FTCategorySortOrderInfo {
    var categoryURL : URL?;
    var categoryName: String;
    var order: Int = Int.max;

    init(_ url: URL? = nil,name: String,order: Int) {
        categoryURL = url;
        categoryName = name;
        self.order = order;
    }
}

struct FTCategoryBookmarkDataItem: Codable  {
    var bookmarkData: Data?
    var sortOrder: Int
    var name: String
    var fileURL: URL?
    init(bookmarkData: Data? = nil, sortOrder: Int, name: String, fileURL: URL?) {
        self.bookmarkData = bookmarkData
        self.sortOrder = sortOrder
        self.name = name
        self.fileURL = fileURL
    }
    
    func resolvedURL() -> URL? {
        if let url = self.fileURL, FileManager().fileExists(atPath: url.path(percentEncoded: false)) {
            return url;
        }
        else if let data = self.bookmarkData {
            var isStale = false;
            if let url = URL.resolvingAliasData(data, isStale: &isStale) {
                return url;
            }
        }
        return nil;
    }
}

struct FTCategoryBookmarkData: Codable {
    let bookmarksData: [FTCategoryBookmarkDataItem]
}

extension FTSidebarViewModel {
     func trackEventForlongpress(item: FTSideBarItem) {
        let eventMapping: [FTSideBarItemType: String] = [
            .home: EventName.sidebar_home_longpress,
            .templates: EventName.sidebar_templates_longpress,
            .unCategorized: EventName.sidebar_unfiled_longpress,
            .trash: EventName.sidebar_trash_longpress,
            .category: EventName.sidebar_category_longpress,
            .starred: EventName.sidebar_starred_longpress,
            .media: EventName.sidebar_photo_longpress,
            .audio: EventName.sidebar_recording_longpress,
            .bookmark: EventName.sidebar_bookmark_longpress,
            .tag:  EventName.sidebar_tag_longpress
        ]

        if let event = eventMapping[item.type] {
            track(event, screenName: ScreenName.sidebar)
        }
    }

     func trackEventForLongPressOptions(item: FTSideBarItem, option: FTSidebarItemContextualOption) {
        let eventMapping: [FTSideBarItemType: [FTSidebarItemContextualOption: String]] = [
            .home: [.openInNewWindow: EventName.home_openinnewwindow_tap],
            .templates: [.openInNewWindow: EventName.templates_openinnewwindow_tap],
            .unCategorized: [.openInNewWindow: EventName.unfiled_openinnewwindow_tap],
            .trash: [.emptyTrash: EventName.trash_emptytrash_tap],
            .category: [
                .openInNewWindow: EventName.category_openinnewwindow_tap,
                .renameCategory: EventName.category_rename_tap,
                .trashCategory: EventName.category_trash_tap
            ],
            .starred: [.openInNewWindow: EventName.starred_openinnewwindow_tap],
            .media: [.openInNewWindow: EventName.sidebar_photo_openinnewwindow_tap],
            .audio: [.openInNewWindow: EventName.sidebar_recording_openinnewindow_tap],
            .tag: [
                .renameTag: EventName.sidebar_tag_rename_tap,
                .deleteTag: EventName.sidebar_tag_delete_tap
            ],
            .bookmark: [.openInNewWindow: EventName.sidebar_bookmark_openinnewwindow_tap]
        ]

        if let event = eventMapping[item.type]?[option] {
            track(event, screenName: ScreenName.sidebar)
        }

     }

    func trackEventForSections(section: FTSidebarSection, isExpand: Bool) {
        let eventMapping: [FTSidebarSectionType: String] = [
            .categories: isExpand ? EventName.sidebar_categories_expand : EventName.sidebar_categories_collapse,
            .media: isExpand ? EventName.sidebar_content_expand : EventName.sidebar_content_collapse,
            .tags: isExpand ? EventName.sidebar_tags_expand : EventName.sidebar_tags_collapse
]
        if let event = eventMapping[section.type] {
            track(event, screenName: ScreenName.sidebar)
        }
    }
}

internal extension FTSidebarViewModel {
    func section(type: FTSidebarSectionType) -> FTSidebarSection {
        guard let item = self.menuItems.first(where: {$0.type == type}) else {
            fatalError("section cannot be nil");
        }
        return item;
    }
}
