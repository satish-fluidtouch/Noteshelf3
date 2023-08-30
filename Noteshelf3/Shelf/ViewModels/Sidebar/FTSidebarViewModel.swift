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
    @Published var selectedSideBarItem: FTSideBarItem?
    @Published var highlightItem: FTSideBarItem?
    @Published var menuItems: [FTSidebarSection] = [] {
        didSet {
             addObservers()
        }
    }
    @Published private var sideBarStatusDict: [String: Bool] = [:]

    //MARK: Private variables
    private(set) var sidebarItemContexualMenuVM: FTSidebarItemContextualMenuVM = FTSidebarItemContextualMenuVM()
    private var systemItems: [FTSideBarItem] = []
    private var categoriesItems: [FTSideBarItem] = []
    private var ns2categoriesItems: [FTSideBarItem] = []
    private var contentItems: [FTSideBarItem] = []
    private var newCollectionAddedOrUpdated: Bool = false
    private var cancellables = [AnyCancellable]()
    private var cancellables1 = [AnyCancellable]()
    private var tags: [FTSideBarItem] = []
    private var selectedSideBarItemType: FTSideBarItemType = .home
    private var lastSelectedTag: String = ""
    private var categoryBookmarksPlistDict: [String:Int] = [:]
    private var sidebarItemsBookmarksData: [String:FTBookmarkedCategoryItem] = [:]

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
                             allowsItemDropping: true)
    }()
   weak var selectedShelfItemCollection: FTShelfItemCollection! {
        set {
            selectedSideBarItem = menuItems.flatMap({$0.items}).first(where: {$0.shelfCollection?.uuid == newValue.uuid}) ?? FTSideBarItem(shelfCollection: newValue)
        }
        get {
            selectedSideBarItem?.shelfCollection ?? FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection
        }
    }
    init(collection: FTShelfItemCollection? = nil) {
        super.init()
        self.selectedShelfItemCollection = collection
        self.addObserverForContextualOperations()
    }
    init(selectedSideBarItemType: FTSideBarItemType, selectedTag:String = "") {
        super.init()
        self.selectedSideBarItemType = selectedSideBarItemType
        self.lastSelectedTag = selectedTag
        self.addObserverForContextualOperations()
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
        (self.menuItems.flatMap({$0.items}).first(where: {$0.type == type}) ?? FTSideBarItem(shelfCollection: FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection))
    }
}
private extension FTSidebarViewModel {
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
            .store(in: &cancellables1)
    }
    func addObservers() {
        self.cancellables.removeAll()
        self.menuItems.forEach({ [weak self] in
            let itemCancellable = $0.objectWillChange.sink(receiveValue: { self?.objectWillChange.send() })
            $0.items.forEach({ [weak self] in
                let menuItemCancellable = $0.objectWillChange.sink(receiveValue: { self?.objectWillChange.send() })
                self?.cancellables.append(menuItemCancellable)
            })
            self?.cancellables.append(itemCancellable)
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
    func renameSideBarItem(_ item: FTSideBarItem,toNewTitle newTitle:String) {
        if item.type == .tag {
            let tagItems = self.menuItems.filter {$0.type == .tags}
            let tagItem = tagItems.flatMap {$0.items}.first(where: {$0.title == newTitle})
            if tagItem == nil {
                self.renametag(item, toNewTitle: newTitle)
            }
        } else if item.type == .category {
            self.renameCategory(item, toTitle: newTitle)
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
                            dropDelegate?.favoriteShelfItem(shelfItem, toPin: true)
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
                let newCategory = FTSideBarItem(shelfCollection: shelfCollection)
                self?.selectedSideBarItem = newCategory
                self?.newCollectionAddedOrUpdated = true
            }
        }
    }
    func renameCategory(_ category:FTSideBarItem, toTitle title:String){
        guard let shelfCollection = category.shelfCollection else {
            return
        }
        let trashCategoryTitle = NSLocalizedString("Trash", comment: "Trash");
        guard title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != trashCategoryTitle.lowercased() else {
            return;
        }
        if title != shelfCollection.displayTitle {
            FTNoteshelfDocumentProvider.shared.renameShelf(shelfCollection, title: title) { [weak self](error,shelfCollection) in
                if let _ = error {
                } else if let shelfCollection = shelfCollection {
                    let currentShelfItem = self?.menuItems.compactMap({ $0.items.first(where: { $0.id == shelfCollection.uuid })}).first
                    self?.newCollectionAddedOrUpdated = true
                    //TODO: Check for EN
//                    shelfCollection.shelfItems(.none,
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
//                            FTCloudBackUpManager.shared.startPublish();
//                    });
                }
            }
        }
    }
    func deleteCategory(_ category: FTSideBarItem){
        guard let shelfCollection = category.shelfCollection else {
            return
        }
        let currentSelectedCategpory = self.selectedSideBarItem
        FTNoteshelfDocumentProvider.shared.moveShelfToTrash(shelfCollection, onCompletion: { [weak self](error, deletedCollection) in
            //self.delegate?.shelfCategory(self, didDeleteCollection: deletedCollection!);
            let categoriesSection = self?.menuItems.first(where: { $0.type == .categories})
            if let deletedCategoryIndex = categoriesSection?.items.firstIndex(where: {$0.id == category.id}) {
                self?.menuItems.first(where: { $0.type == .categories})?.items.remove(at: deletedCategoryIndex)
                let sideBarItemTobeSelected: FTSideBarItem!
                if category.id == currentSelectedCategpory?.shelfCollection?.uuid {//If current category is being deleted
                        if let totalCategories = categoriesSection?.items.count, totalCategories > 0 {
                            if deletedCategoryIndex == totalCategories, let lastCategory = categoriesSection?.items.last {//Choose last category if it was last
                                sideBarItemTobeSelected = lastCategory
                            }
                            else {//Choose a category with same index
                                sideBarItemTobeSelected = categoriesSection?.items[deletedCategoryIndex ];
                            }
                        }
                        else {
                            sideBarItemTobeSelected = self?.menuItems.first?.items.first // pointing to all notes incase of no categories
                        }
                }
                else {
                    sideBarItemTobeSelected = currentSelectedCategpory;
                }
                self?.selectedSideBarItem = sideBarItemTobeSelected
                self?.newCollectionAddedOrUpdated = true
            }
            //self.delegate?.shelfCollection(self, didSelectCollection: shelfItemCollectionToShow);
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
        self.configureMenuOptions()
    }
    private func configureMenuOptions() {
        self.fetchSidebarMenuItems()
    }
    func updateUserCreatedCategories() {
        self.fetchUserCreatedCategories()
    }
    func updateTags() {
        self.fetchAllTags()
    }
    private func fetchUserCreatedCategories() {
        userCreatedSidebarItems { [weak self] sidebarItems in
            guard let self = self else { return }
            self.categoriesItems = self.sortCategoriesBasedOnStoredPlistOrder(sidebarItems)
            self.buildSideMenuItems()
        }
    }
    private func userCreatedSidebarItems(onCompeltion : @escaping([FTSideBarItem]) -> Void) {
        FTNoteshelfDocumentProvider.shared.fetchAllCollections { collections in
            let newlyCreatedSidebarItems = collections.map { shelfItem -> FTSideBarItem in
                let item = FTSideBarItem(shelfCollection: shelfItem)
                item.id = shelfItem.uuid
                item.isEditable = true
                item.allowsItemDropping = true
                item.type = .category
                return item
            }

            FTNoteshelfDocumentProvider.shared.ns2Shelfs { collections in
                let NS2Items = collections.map { shelfItem -> FTSideBarItem in
                    let item = FTSideBarItem(shelfCollection: shelfItem)
                    item.id = shelfItem.uuid
                    item.isEditable = false
                    item.allowsItemDropping = false
                    item.type = .ns2Category
                    return item
                }
                self.ns2categoriesItems.removeAll()
                self.ns2categoriesItems.append(contentsOf: NS2Items)
                onCompeltion(newlyCreatedSidebarItems)
            }
//            onCompeltion(newlyCreatedSidebarItems)
        }
    }

    private func fetchAllTags() {
        let allTags = FTCacheTagsProcessor.shared.cachedTags()
        var tags: [FTSideBarItem] = [FTSideBarItem]()
        tags = allTags.map { tag -> FTSideBarItem in
            let tagItem = FTTagModel(text: tag)
            let item = FTSideBarItem(id: tagItem.id, title: tagItem.text, icon: .number, isEditable: true, isEditing: false, type: FTSideBarItemType.tag, allowsItemDropping: false)
            return item
        }
        self.buildGlobalTagsOptions(tags)
    }

    func updateUnfiledCategory() {
        FTNoteshelfDocumentProvider.shared.uncategorizedNotesCollection { [weak self] collection in
            if let unfiledCollection = collection {
                self?.setCollectionToSystemType(.unCategorized, collection: unfiledCollection)
            }
        }
    }

    private func fetchSidebarMenuItems() {

        // Fetching ns2 categories

        //First section items creation
        self.buildSystemMenuOptions()

        // Fetching default/migrated categories for second section of side menu
        userCreatedSidebarItems { [weak self] sidebarItems in
            guard let self = self else { return }
            self.categoriesItems = self.sortCategoriesBasedOnStoredPlistOrder(sidebarItems)
        }

        //Assigning respective shelf item collections to top section UI items
        self.setCollectionToSystemType(.home, collection: FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection)
        self.setCollectionToSystemType(.starred, collection: FTNoteshelfDocumentProvider.shared.starredShelfItemCollection())
        FTNoteshelfDocumentProvider.shared.trashShelfItemCollection { trashCollection in
            self.setCollectionToSystemType(.trash, collection: trashCollection)
        }
        fetchNS2Categories { [weak self] items in
            guard let self else { return }
            self.ns2categoriesItems.removeAll()
            self.ns2categoriesItems.append(contentsOf: items)
            //TODO: To be refactored
            self.buildSideMenuItems()
        }
        self.updateUnfiledCategory()

        self.buildMediaMenuOptions()
        self.fetchAllTags()

    }
    static private func getTemplatesSideBarItem() -> FTSideBarItem {
        return FTSideBarItem(title: NSLocalizedString("Templates", comment: "Templates"),
                             icon: FTIcon.templates,
                             isEditable: true,
                             type: FTSideBarItemType.templates)
    }
    private func setCollectionToSystemType(_ type: FTSideBarItemType, collection: FTShelfItemCollection?) {
        if let sidebarItem = self.systemItems.first(where: {$0.type == type}), let collection {
            sidebarItem.shelfCollection = collection
            sidebarItem.id = collection.uuid
        }
    }
    private func createSideBarItemWith(title: String, type: FTSideBarItemType, allowsItemDropping: Bool,icon: FTIcon) -> FTSideBarItem {
        return FTSideBarItem(title: title,
                             icon: icon,
                             isEditable: true,
                             type: type,
                             allowsItemDropping: allowsItemDropping)
    }
    private func buildSystemMenuOptions() {
        systemItems.removeAll()
        //Home
        let homeSidebarItem = self.createSideBarItemWith(title: "sidebar.topSection.home", type: .home, allowsItemDropping: false, icon: FTIcon.allNotes)
        systemItems.append(homeSidebarItem)
        // Favorites
        let favoritesSidebarItem = self.createSideBarItemWith(title: "Starred", type: .starred, allowsItemDropping: true, icon: .favorites)
        systemItems.append(favoritesSidebarItem)
        //Uncategorized
        let unCategorizedSidebarItem = self.createSideBarItemWith(title: "Unfiled", type: .unCategorized, allowsItemDropping: true, icon: .unsorted)
        systemItems.append(unCategorizedSidebarItem)
         //Templates
        let templatesSidebarItem = FTSidebarViewModel.getTemplatesSideBarItem()
        systemItems.append(templatesSidebarItem)
        //Trash
        let trashSidebarItem = self.createSideBarItemWith(title: "Trash", type: .trash, allowsItemDropping: true, icon: .trash)
        systemItems.append(trashSidebarItem)
    }

    private func buildMediaMenuOptions() {
        let photos = FTSideBarItem(title: NSLocalizedString("Photo", comment: "Photo"), icon: FTIcon.photo, isEditable: true, isEditing: false, type: FTSideBarItemType.media, allowsItemDropping: false)
        let recording = FTSideBarItem(title: NSLocalizedString("Recording", comment: "Recording"), icon: FTIcon.audioNote, isEditable: true, isEditing: false, type: FTSideBarItemType.audio, allowsItemDropping: false)
        let bookmarks = FTSideBarItem(title: NSLocalizedString("Bookmark", comment: "Bookmark"), icon: FTIcon.bookmark, isEditable: true, type: FTSideBarItemType.bookmark,allowsItemDropping: false)
        self.contentItems = [photos, recording, bookmarks]
    }
    private func buildGlobalTagsOptions(_ tags: [FTSideBarItem]) {
        var totalTagSidebarItems : [FTSideBarItem] = []
        let allTagsSidebarItem = FTSideBarItem(title: "sidebar.allTags".localized, icon:  .number, isEditable: false, isEditing: false, type: FTSideBarItemType.tag, allowsItemDropping: false)
        totalTagSidebarItems = [allTagsSidebarItem]
        totalTagSidebarItems += tags
        self.tags = totalTagSidebarItems
    }

    private func buildSideMenuItems(){
        self.menuItems = []
        self.menuItems = [FTSidebarSection(type: FTSidebarSectionType.all, items: self.systemItems,supportsRearrangeOfItems: false)]
        self.menuItems.append(FTSidebarSection(type: .categories, items: self.categoriesItems,supportsRearrangeOfItems: true))
        if !ns2categoriesItems.isEmpty {
            self.menuItems.append(FTSidebarSection(type: .ns2Categories, items: self.ns2categoriesItems,supportsRearrangeOfItems: false))
        }
        self.menuItems.append(FTSidebarSection(type: .media, items: self.contentItems,supportsRearrangeOfItems: false))
        self.menuItems.append(FTSidebarSection(type: .tags, items: self.tags,supportsRearrangeOfItems: false))
        self.setSideBarItemSelection()
    }
     func setSideBarItemSelection(){
        if let selectedSideBarItem = self.selectedSideBarItem {
            let collectionTypes: [FTSideBarItemType] = [.home,.starred,.unCategorized,.trash,.category]
            if collectionTypes.contains(where: {$0 == selectedSideBarItem.type}) {
                let selectedItem = menuItems.compactMap( { $0.items.first(where:{ $0.shelfCollection?.uuid == selectedSideBarItem.shelfCollection?.uuid })}).first
                self.selectedSideBarItem = selectedItem
            } else if selectedSideBarItem.type == .tag {
                let selectedItem = menuItems.compactMap( { $0.items.first(where:{ $0.id == selectedSideBarItem.id })}).first
                if selectedItem != nil {
                    self.selectedSideBarItem = selectedItem
                } else if let selectedSideBarItem = menuItems.compactMap( { $0.items.first(where:{ $0.title == "sidebar.allTags".localized })}).first {
                    self.selectedSideBarItem = selectedSideBarItem
                    self.delegate?.didTapOnSidebarItem(selectedSideBarItem)
                }
            } else {
                let selectedItem = menuItems.compactMap( { $0.items.first(where:{ $0.id == selectedSideBarItem.id })}).first
                self.selectedSideBarItem = selectedItem
            }
            if newCollectionAddedOrUpdated {
                newCollectionAddedOrUpdated = false
                self.delegate?.didTapOnSidebarItem(selectedSideBarItem)
            }
        } else {
            if selectedSideBarItemType == .tag, let selectedSideBarItem = menuItems.compactMap({$0.items.first(where:{$0.type == selectedSideBarItemType && $0.title.lowercased() == lastSelectedTag.lowercased()})}).first {
                self.selectedSideBarItem = selectedSideBarItem
            }  else {
                let selectedSideBarItem = menuItems.compactMap({$0.items.first(where:{$0.type == selectedSideBarItemType})}).first
                self.selectedSideBarItem = selectedSideBarItem
            }
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
        if let sideBarItemsOrderDict = sideBarDict["SideBarItemsOrder"] as? [String: Any], let categoriesOrderDict = sideBarItemsOrderDict["categories"] as? [String:Int] {
                self.categoryBookmarksPlistDict = categoriesOrderDict
        }
    }
    func updateSideBarSectionStatus(_ section: FTSidebarSection, status: Bool) {
        self.sideBarStatusDict[section.type.rawValue] = status
        FTSidebarManager.save(sideBarData: self.sideBarStatusDict)
    }
    func updateSidebarCategoriesOrderUsingDict(_ categoriesOrderDict:[String:Int]){
        FTSidebarManager.saveCategoriesOrder(categoriesOrderDict)
    }
    func reOrderSidebarSectionItems(_ sectionType: FTSidebarSectionType,fromOrder: Int, toOrder: Int) {
        if sectionType == .categories {
            self.updateCategoriesOrder(fromOrder, toOrder: toOrder)
        }
    }
    private func updateCategoriesOrder(_ fromOrder: Int, toOrder: Int){
        if !self.categoryBookmarksPlistDict.isEmpty,
           let categoryItems = self.menuItems.first(where: {$0.type == .categories})?.items,
           !categoryItems.isEmpty {
            if let fromPositionSidebarItem = self.menuItems.first(where: {$0.type == .categories})?.items[fromOrder],
               (toOrder >= 0 && toOrder < (categoryItems.count)),
               let toPositionSidebarItem = self.menuItems.first(where: {$0.type == .categories})?.items[toOrder],
               let fromPositionCollection = fromPositionSidebarItem.shelfCollection,
               let fromSidebarItemAliasFile = sidebarItemsBookmarksData[fromPositionCollection.URL.lastPathComponent],
               let toPositionCollection = toPositionSidebarItem.shelfCollection,
               let toSideBarItemAliasFile =  sidebarItemsBookmarksData[toPositionCollection.URL.lastPathComponent] {
                    self.categoryBookmarksPlistDict[fromSidebarItemAliasFile.collectionName] = toOrder
                    self.categoryBookmarksPlistDict[toSideBarItemAliasFile.collectionName] = fromOrder
                    FTSidebarManager.saveCategoriesOrder(self.categoryBookmarksPlistDict)
            }
        }
    }

    private var bookMarksDirectoryURL: URL {
        let documentURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let bookMarksDirectoryURL = documentURL.appendingPathComponent("Bookmarks",isDirectory: true)
        return bookMarksDirectoryURL
    }
    private func createAliasFileForShelfCategory(_ shelfItemCollection: FTShelfItemCollection)-> URL? {
        do {
            let bookMarkData = try shelfItemCollection.URL.bookmarkData(options: .suitableForBookmarkFile,relativeTo: shelfItemCollection.URL)
            var isDir = ObjCBool.init(false);
            if(!FileManager.default.fileExists(atPath: bookMarksDirectoryURL.path, isDirectory: &isDir) || !isDir.boolValue) {
                try FileManager.default.createDirectory(at: bookMarksDirectoryURL, withIntermediateDirectories: true, attributes: nil);
            }
            let aliasFileURL = bookMarksDirectoryURL.appendingPathComponent("\(shelfItemCollection.URL.lastPathComponent)")
            try URL.writeBookmarkData(bookMarkData, to:aliasFileURL)
            return aliasFileURL
        }
        catch {
            print("Exception",error)
        }
        return nil
    }
    private func sortCategoriesBasedOnStoredPlistOrder(_ sidebarItems:[FTSideBarItem]) -> [FTSideBarItem] {
        var orderedSideBarItems: [FTSideBarItem: Int] = [:]
        sidebarItemsBookmarksData = FTBookmarkedCategoryItem.bookmarkedItems(aliasFilesPlist: self.categoryBookmarksPlistDict);

        for sideBarItem in sidebarItems {
            if !self.categoryBookmarksPlistDict.isEmpty, let collection = sideBarItem.shelfCollection,
               let aliasFileDetails = sidebarItemsBookmarksData[collection.URL.lastPathComponent] {
                let collectionOrder = aliasFileDetails.sortOrder
                orderedSideBarItems[sideBarItem] = collectionOrder
            }else {
                let maxOrderValue = self.categoryBookmarksPlistDict.values.max() ?? 0
                let newOrderValue = self.categoryBookmarksPlistDict.isEmpty ? 0 : maxOrderValue + 1
                if let shelfItemCollection = sideBarItem.shelfCollection, let aliasFileURL = self.createAliasFileForShelfCategory(shelfItemCollection){
                    self.categoryBookmarksPlistDict[aliasFileURL.path.lastPathComponent] = newOrderValue
                }
                orderedSideBarItems[sideBarItem] = newOrderValue
            }
        }
        self.updateSidebarCategoriesOrderUsingDict(self.categoryBookmarksPlistDict)
        return orderedSideBarItems.sorted(by: {$0.value < $1.value}).compactMap({$0.key})
    }
    func updateCategoryBookMarksOnCategoryDeletion(){
        var deletableCategoryBookMarks:[String] = []
        for lastPathComponent in self.categoryBookmarksPlistDict.keys {
            let aliasFileURL = bookMarksDirectoryURL.appendingPathComponent(lastPathComponent)
            let resolvedURL = try? URL(resolvingAliasFileAt: aliasFileURL, options: .withoutImplicitStartAccessing) // actual category file
            if resolvedURL == nil { // category is deleted
                deletableCategoryBookMarks.append(lastPathComponent)
            }
        }
        for deletedCategory in deletableCategoryBookMarks {
            self.categoryBookmarksPlistDict.removeValue(forKey: deletedCategory)
        }
        self.updateSidebarCategoriesOrderUsingDict(self.categoryBookmarksPlistDict)
    }
}

class FTBookmarkedCategoryItem {
    var collectionURL : URL;
    var collectionName: String;
    var sortOrder: Int = Int.max;

    init(_ url: URL,name: String,order: Int) {
        collectionURL = url;
        collectionName = name;
        sortOrder = order;
    }

    static func bookmarkedItems(aliasFilesPlist : [String:Int]) -> [String:FTBookmarkedCategoryItem] {
        var items = [String:FTBookmarkedCategoryItem]();
        for eachItem in aliasFilesPlist {
            let path = eachItem.key;
            let documentURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            let bookMarksDirectoryURL = documentURL.appendingPathComponent("Bookmarks",isDirectory: true)
            let aliasFileURL = bookMarksDirectoryURL.appendingPathComponent(path)
            do {
                let resolvedURL = try URL(resolvingAliasFileAt: aliasFileURL, options: .withoutImplicitStartAccessing)
                let item = FTBookmarkedCategoryItem(resolvedURL,name:resolvedURL.lastPathComponent,order: eachItem.value);
                items[resolvedURL.lastPathComponent] = item;
            }
            catch {
                print("Exception in fetching collection actual path", error,"For:", eachItem)
            }
        }
        return items;
    }
}
