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
    @Published private var sideBarStatusDict: [String: Bool] = [:]

    //MARK: Private variables
    private(set) var sidebarItemContexualMenuVM: FTSidebarItemContextualMenuVM = FTSidebarItemContextualMenuVM()
    private var categoriesItems: [FTSideBarItem] = []
    private var newCollectionAddedOrUpdated: Bool = false
    private var cancellables = [AnyCancellable]()
    private var selectedSideBarItemType: FTSideBarItemType = .home
    private var lastSelectedTag: String = ""
    private var categoryBookmarksData: FTCategoryBookmarkData = FTCategoryBookmarkData(bookmarksData: [])
    private var sidebarItemsBookmarksData: [FTCategorySortOrderInfo] = []

    var topSectionGridItems:[FTSideBarItem] {
        return menuItems.first(where: {$0.type == .all})?.items ?? []
    }
    var activeReorderingSidebarSectionType: FTSidebarSectionType?

    var currentSideBarDropItem: FTSideBarItem?
    var allowableSidebarSectionsInPhone: [FTSidebarSectionType] = [.all,.categories,.media,.tags]
    var sideBarItemWidth: CGFloat = 280

    //MARK: Computed variables
    lazy var newItem: FTSideBarItem = {
        return FTSideBarItem(title: "",
                             icon: FTIcon.folder,
                             isEditable: true,
                             isEditing: false,
                             type: .category,
                             allowsItemDropping: false)
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
        self.addObserverForContextualOperations()
    }
    init(selectedSideBarItemType: FTSideBarItemType, selectedTag:String = "") {
        super.init()
        self.selectedSideBarItemType = selectedSideBarItemType
        if selectedSideBarItemType == .home {
            selectedShelfItemCollection = FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection
        }
        self.lastSelectedTag = selectedTag
        self.addObserverForContextualOperations()
    }
    deinit {
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
        removeNotificationObservers() // remove if its already added
//        NotificationCenter.default.addObserver(self, selector: #selector(self.categoryDidUpdate(_:)), name: .categoryItemsDidUpdateNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(self.updateTagItems(_:)), name: .refresSideMenuNotification, object: nil)
    }
    
    func removeNotificationObservers() {
//        NotificationCenter.default.removeObserver(self, name: .categoryItemsDidUpdateNotification, object: nil)
//        NotificationCenter.default.removeObserver(self, name: .refresSideMenuNotification, object: nil)
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
    
//    @objc func categoryDidUpdate(_ notification : Notification) {
//        self.updateUserCreatedCategories()
//    }
        
//    @objc func updateTagItems(_ notification : Notification) {
//        if let selectedSideBarItem = self.selectedSideBarItem, selectedSideBarItem.type == .tag {
//            if let info = notification.userInfo, let type = info["type"] as? String {
//                let tagItems = self.menuItems.filter {$0.type == .tags}
//                if type == "rename", let tag = info["tag"] as? String, let renamedTag = info["renamedTag"] as? String {
//                    let tagItem = tagItems.flatMap {$0.items}.first(where: {$0.title == tag})
//                    tagItem?.title = renamedTag
//                } else if type == "add", let tag = info["tag"] as? String {
//                    let item = FTSideBarItem(title: tag, icon: .number, isEditable: true, isEditing: false, type: FTSideBarItemType.tag, allowsItemDropping: false)
//                    tagItems.first?.items.append(item)
//                } else if type == "delete", let tag = info["tag"] as? String {
//                    tagItems.first?.items = tagItems.flatMap({$0.items.filter({$0.title != tag})})
//                }
//                if var items = tagItems.first?.items {
//                    let allTags = items.first(where: {$0.type == .allTags})
//                    items.removeAll(where: {$0.type == .allTags})
//                    var sortedArray = items.sorted(by: { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending })
//                    if let allTags {
//                        sortedArray.insert(allTags, at: 0)
//                    }
//                    self.menuItems.first(where: {$0.type == .tags})?.items = sortedArray
//                    self.updateTagsSection(items: sortedArray)
//                }
//                self.setSideBarItemSelection()
//            } else {
//                self.updateTags()
//            }
//        } else {
//            self.updateTags()
//        }
//    }

    func addObservers() {
        self.menuItems.forEach({ menuItem in
            menuItem.objectWillChange
                .sink(receiveValue: { [weak self] in self?.objectWillChange.send()})
                .store(in: &cancellables)

            menuItem.items.forEach({ eachItem in
                eachItem.objectWillChange.sink(receiveValue: { [weak self] in self?.objectWillChange.send() })
                    .store(in: &cancellables)
            })
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
            let categoriesSection = self?.menuItems.first(where: { $0.type == .categories})
            if let deletedCategoryIndex = categoriesSection?.items.firstIndex(where: {$0.id == category.id}) {
                self?.menuItems.first(where: { $0.type == .categories})?.items.remove(at: deletedCategoryIndex)
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
    func configureUIOnViewLoad() {
        self.fetchSideBarData()
        self.fetchSidebarMenuItems()
    }

    func updateUserCreatedCategories() {
//        self.fetchUserCreatedCategories()
    }
    
//    private func fetchUserCreatedCategories() {
//        userCreatedSidebarItems { [weak self] sidebarItems in
//            guard let self = self else { return }
//            DispatchQueue.global().async {
//                self.categoriesItems = self.sortCategoriesBasedOnStoredPlistOrder(sidebarItems,performURLResolving: true)
//                runInMainThread {
//                    if let item = self.menuItems.first(where: {$0.type == .categories}) {
//                        item.items = self.categoriesItems;
//                    }
//                }
//            }
//        }
//    }
//    private func userCreatedSidebarItems(onCompeltion : @escaping([FTSideBarItem]) -> Void) {
//        FTNoteshelfDocumentProvider.shared.fetchAllCollections { collections in
//            let newlyCreatedSidebarItems = collections.filter({!$0.isUnfiledNotesShelfItemCollection}).map { shelfItem -> FTSideBarItem in
//                let item = FTSideBarItem(shelfCollection: shelfItem)
//                item.id = shelfItem.uuid
//                item.isEditable = true
//                item.allowsItemDropping = true
//                item.type = .category
//                return item
//            }
//            onCompeltion(newlyCreatedSidebarItems)
//        }
//    }

    private func fetchSidebarMenuItems() {
        // Fetching default/migrated categories for second section of side menu
//        userCreatedSidebarItems { [weak self] sidebarItems in
//            guard let self = self else { return }
//            self.categoriesItems.removeAll()
//            self.categoriesItems.append(contentsOf: self.sortCategoriesBasedOnStoredPlistOrder(sidebarItems))
//        }

        //Assigning respective shelf item collections to top section UI items
        self.buildSideMenuItems()
//        DispatchQueue.global().async {
//            self.categoriesItems = self.sortCategoriesBasedOnStoredPlistOrder(self.categoriesItems,performURLResolving: true)
//            runInMainThread {
//                if let item = self.menuItems.first(where: {$0.type == .categories}) {
//                    item.items = self.categoriesItems;
//                }
//            }
//        }

    }

    private func createSideBarItemWith(title: String, type: FTSideBarItemType, allowsItemDropping: Bool,icon: FTIcon) -> FTSideBarItem {
        return FTSideBarItem(title: title,
                             icon: icon,
                             isEditable: true,
                             type: type,
                             allowsItemDropping: allowsItemDropping)
    }

    private func buildSideMenuItems(){
        self.menuItems.append(FTSidebarSectionSystem());
        self.menuItems.append(FTSidebarSectionUserShelfs())
//        self.menuItems.append(FTSidebarSection(type: .categories, items: self.categoriesItems,supportsRearrangeOfItems: true))
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
    func getSideBarStatusForSection(_ section: FTSidebarSection)-> Bool {
        self.sideBarStatusDict[section.type.rawValue] ?? false
    }
    private func fetchSideBarData() {
        FTSidebarManager.copyBundleDataIfNeeded()
        let sideBarDict = FTSidebarManager.getSideBarData()
        if let sideBarStatucDict = sideBarDict["SideBarStatus"] as? [String: Bool] {
            self.sideBarStatusDict = sideBarStatucDict
        }
        if let sideBarItemsOrderDict = sideBarDict["SideBarItemsOrder"] as? [String: Any], let categoryBookmarkRawData = sideBarItemsOrderDict["categories"] as? Data, let categoryBookmarkData = try? PropertyListDecoder().decode(FTCategoryBookmarkData.self, from: categoryBookmarkRawData) {
                self.categoryBookmarksData = categoryBookmarkData
        }
    }
    func updateSideBarSectionStatus(_ section: FTSidebarSection, status: Bool) {
        self.sideBarStatusDict[section.type.rawValue] = status
        FTSidebarManager.save(sideBarData: self.sideBarStatusDict)
    }
    func updateSidebarCategoriesOrderUsingDict(_ categoriesBookmarData:FTCategoryBookmarkData){
        do {
            try FTSidebarManager.saveCategoriesBookmarData(categoriesBookmarData)
            self.categoryBookmarksData = categoriesBookmarData
        }
        catch {
            debugPrint("Failed to save categories order to plist.")
        }
    }
    func reOrderSidebarSectionItems(_ sectionType: FTSidebarSectionType,fromOrder: Int, toOrder: Int) {
        if sectionType == .categories {
            self.updateCategoriesOrder(fromOrder, toOrder: toOrder)
        }
    }
    private func updateCategoriesOrder(_ fromOrder: Int, toOrder: Int){
        if !self.categoryBookmarksData.bookmarksData.isEmpty,
           let categoryItems = self.menuItems.first(where: {$0.type == .categories})?.items,
           !categoryItems.isEmpty {
            if let fromPositionSidebarItem = self.menuItems.first(where: {$0.type == .categories})?.items[fromOrder],
               (toOrder >= 0 && toOrder < (categoryItems.count)),
               let toPositionSidebarItem = self.menuItems.first(where: {$0.type == .categories})?.items[toOrder],
               let fromPositionCollection = fromPositionSidebarItem.shelfCollection,
               let fromSidebarItemSortInfo = sidebarItemsBookmarksData.first(where: {$0.categoryName == fromPositionCollection.URL.lastPathComponent}),
               let toPositionCollection = toPositionSidebarItem.shelfCollection,
               let toSideBarItemSortInfo =  sidebarItemsBookmarksData.first(where: {$0.categoryName == toPositionCollection.URL.lastPathComponent}) {
                fromSidebarItemSortInfo.order = toOrder
                toSideBarItemSortInfo.order = fromOrder
                let latestSortedInfo = self.updateCategoryBookmarkDataBasedOnCategorySortInfo()
                self.updateSidebarCategoriesOrderUsingDict(FTCategoryBookmarkData(bookmarksData: latestSortedInfo))
            }
        }
    }
    private func updateCategoryBookmarkDataBasedOnCategorySortInfo() -> [FTCategoryBookmarkDataItem] {
        var plistBookmarkData : [FTCategoryBookmarkDataItem] = []
        self.categoryBookmarksData.bookmarksData.forEach { eachItem in
            if let sortInfo = self.sidebarItemsBookmarksData.first(where: {$0.categoryName == eachItem.name}) {
                plistBookmarkData.append(FTCategoryBookmarkDataItem(bookmarkData: eachItem.bookmarkData,
                                                                    sortOrder: sortInfo.order,
                                                                    name: sortInfo.categoryName,
                                                                    fileURL: eachItem.fileURL))
            }
        }
        return plistBookmarkData
    }
    private func sortCategoriesBasedOnStoredPlistOrder(_ sidebarItems:[FTSideBarItem],performURLResolving:Bool = false) -> [FTSideBarItem] {
        var orderedSideBarItems : [FTSideBarItem: Int] = [:]
        let sortInfo = FTCategoryBookmarkData.categoriesOrderBasedOn(plistfechtedBookmarkData: self.categoryBookmarksData,performURLResolving: performURLResolving)
        sidebarItemsBookmarksData =  sortInfo.categorySortOrderInfo
        self.categoryBookmarksData = FTCategoryBookmarkData(bookmarksData: sortInfo.plistBookmarkData)
        var bookmarksData: [FTCategoryBookmarkDataItem] = self.categoryBookmarksData.bookmarksData
        for sideBarItem in sidebarItems {
            if let collection = sideBarItem.shelfCollection {
                if var existingCollectionInPlistIndex = bookmarksData.firstIndex(where:{$0.name == collection.URL.lastPathComponent}) {
                    let existingCollectionInPlist = bookmarksData[existingCollectionInPlistIndex]
                    let collectionOrder = existingCollectionInPlist.sortOrder
                    if existingCollectionInPlist.fileURL != collection.URL, let newBookmarkItem = newCategoryBookmarkDataItemForCollection(collection, sortOrder: collectionOrder) { // updating url in already collection existing plist data
                        bookmarksData.remove(at: existingCollectionInPlistIndex)
                        bookmarksData.append(newBookmarkItem)
                    }
                    orderedSideBarItems[sideBarItem] = collectionOrder
                } else {
                    let maxOrderValue = bookmarksData.map({$0.sortOrder}).max() ?? 0
                    let newOrderValue = bookmarksData.isEmpty ? 0 : maxOrderValue + 1
                    if let newBookmarkItem = newCategoryBookmarkDataItemForCollection(collection, sortOrder: newOrderValue){
                        bookmarksData.append(newBookmarkItem)
                        orderedSideBarItems[sideBarItem] = newOrderValue
                    }
                }
            }
        }
        self.updateSidebarCategoriesOrderUsingDict(FTCategoryBookmarkData(bookmarksData: bookmarksData))
        return orderedSideBarItems.sorted(by: {$0.value < $1.value}).compactMap({$0.key})
    }
    private func newCategoryBookmarkDataItemForCollection(_ collection: FTShelfItemCollection, sortOrder: Int) -> FTCategoryBookmarkDataItem? {
        if let bookmarkData = URL.aliasData(collection.URL){
            return FTCategoryBookmarkDataItem(bookmarkData: bookmarkData,
                                       sortOrder: sortOrder,
                                       name: collection.URL.lastPathComponent,
                                       fileURL: collection.URL)
        }
        return nil
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
}

struct CategoryBookmarkResolvedData {
    let plistBookmarkData:[FTCategoryBookmarkDataItem]
    let categorySortOrderInfo: [FTCategorySortOrderInfo]
}

struct FTCategoryBookmarkData: Codable {
    let bookmarksData: [FTCategoryBookmarkDataItem]

    static func categoriesOrderBasedOn(plistfechtedBookmarkData : FTCategoryBookmarkData,performURLResolving:Bool = false) -> CategoryBookmarkResolvedData {
        var categoriesSortOrderinfo = [FTCategorySortOrderInfo]();
        var plistBookmarkData:[FTCategoryBookmarkDataItem] = []
        for eachItem in plistfechtedBookmarkData.bookmarksData {
            if performURLResolving {
                var isStale = false;
                if let categoryURL = eachItem.fileURL, FileManager.default.fileExists(atPath: categoryURL.path) { // As file exist at same location, avoiding resolving alias data
                    plistBookmarkData.append(FTCategoryBookmarkDataItem(bookmarkData: eachItem.bookmarkData,
                                                                        sortOrder: eachItem.sortOrder,
                                                                        name: eachItem.name,
                                                                        fileURL: eachItem.fileURL))
                    let item = FTCategorySortOrderInfo(categoryURL,name:categoryURL.lastPathComponent,order: eachItem.sortOrder);
                    categoriesSortOrderinfo.append(item);
                } else {
                    // fetching actual url by resolving alias data
                    if var data = eachItem.bookmarkData,
                       let fileURl = URL.resolvingAliasData(data, isStale: &isStale),
                       FileManager.default.fileExists(atPath: fileURl.path) {
                        if isStale, let aliasData = URL.aliasData(fileURl) {
                            data = aliasData
                        }
                        plistBookmarkData.append(FTCategoryBookmarkDataItem(bookmarkData: data,
                                                                            sortOrder: eachItem.sortOrder,
                                                                            name: fileURl.lastPathComponent,
                                                                            fileURL: fileURl))
                        let item = FTCategorySortOrderInfo(fileURl,name:fileURl.lastPathComponent,order: eachItem.sortOrder);
                        categoriesSortOrderinfo.append(item);
                    }
                }
            } else {
                if let categoryURL = eachItem.fileURL, FileManager.default.fileExists(atPath: categoryURL.path) {
                    plistBookmarkData.append(eachItem)
                    let item = FTCategorySortOrderInfo(name:eachItem.name,order: eachItem.sortOrder);
                    categoriesSortOrderinfo.append(item);
                }
            }
        }
        return CategoryBookmarkResolvedData(plistBookmarkData: plistBookmarkData, categorySortOrderInfo: categoriesSortOrderinfo);
    }
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
