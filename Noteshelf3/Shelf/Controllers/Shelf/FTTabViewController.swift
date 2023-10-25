//
//  FTTabViewController.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 20/04/22.
//

import UIKit
import SwiftUI
import FTTemplatesStore

enum FTPhoneModeTabBarItem {
    case shelf
    case contents
    case addItem
    case search
    case favorites

    var title: String {
        let title: String
        switch self {
        case .shelf:
            title = "Shelf"
        case .contents:
            title = "Contents"
        case .addItem:
            title = ""
        case .search:
            title = "Search"
        case .favorites:
            title = "Favorites"
        }
        return title
    }
    var icon: UIImage? {
        let icon: UIImage?
        switch self {
        case .shelf:
            icon = UIImage(systemName: "books.vertical")
        case .contents:
            icon = UIImage(systemName: "photo.on.rectangle")
        case .addItem:
            icon = UIImage(named: "addItem")
        case .search:
            icon = UIImage(systemName: "magnifyingglass")
        case .favorites:
            icon = UIImage(systemName: "star")
        }
        return icon
    }
    var tag: Int {
        let tag: Int
        switch self {
        case .shelf:
            tag = 1
        case .contents:
            tag = 2
        case .addItem:
            tag = 3
        case .search:
            tag = 4
        case .favorites:
            tag = 5
        }
        return tag
    }
}

class FTTabViewController: UITabBarController {

    var isInSearchMode: Bool = false
    var isInGroupMode: Bool = false

    var shelfItemCollection: FTShelfItemCollection!
    var groupItemIfExists: FTGroupItemProtocol?
    var shelfNavigationController: UINavigationController?

    private var sideMenuController: FTSideMenuViewController?
    private var favoritesViewController: FTShelfViewControllerNew?
    private(set) var globalSearchVc: FTGlobalSearchController?

    weak var tagsControllerDelagate: FTTagsViewControllerDelegate?
    weak var shelfViewModelDelegate: FTShelfViewModelProtocol?
    weak var shelfNewNoteDelegate: FTShelfNewNoteDelegate?
    weak var mediaDelegate: FTShelfMediaDelegate?
    weak var globalSearchDelegate: FTGlobalSearchDelegate?
    weak var tagsDelegate: FTShelfTagsPageDelegate?

    var currentShelfViewModel: FTShelfViewModel? {
        if let shelfVc = self.shelfNavigationController?.topViewController as? FTShelfViewControllerNew {
            return shelfVc.shelfViewModel
        }
        return nil
    }
    static func instantiateFromStroyboard() -> FTTabViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "FTTabViewController") as? FTTabViewController else {
            fatalError("FTTabViewController doesnt exist")
        }
        return viewController
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        shelfNavigationController = FTNavigationController()
        setTabBarItems()
        self.delegate = self
    }
}
extension FTTabViewController {
    func getSecondaryViewControllerWith(collection: FTShelfItemCollection, groupItem: FTGroupItemProtocol?) -> FTShelfViewControllerNew {
        let shelfViewModel = FTShelfViewModel(collection: collection , groupItem: groupItem)
        shelfViewModel.delegate = shelfViewModelDelegate
        shelfViewModel.tagsControllerDelegate = tagsControllerDelagate
        let detailViewController = FTShelfViewControllerNew(shelfViewModel: shelfViewModel, shelfMenuOverlayInfo: FTShelfMenuOverlayInfo())
        shelfViewModel.compactDelegate = detailViewController
        if groupItem != nil {
            detailViewController.title =  groupItem?.displayTitle ?? ""
        } else {
            detailViewController.title =  collection.displayTitle
        }
        detailViewController.shelfItemCollection = collection
        detailViewController.parentShelfItem = groupItem
        return detailViewController
    }
}
private extension FTTabViewController {
    func setTabBarItems(){
        self.setViewControllers([getShelfTabItem(),getContentTabItem(),getAddTabItem(),getSearchTabItem(),getFavoritesTabItem()], animated:false)
    }
    func getShelfTabItem() -> UIViewController {
        sideMenuController = self.getPrimaryViewController()
        sideMenuController?.navigationItem.backButtonDisplayMode = .minimal
        let detailController = self.getSecondaryViewControllerWith(collection: shelfItemCollection, groupItem: nil)
        var viewControllers: [UIViewController] = []
        if let menuController = self.sideMenuController {
            viewControllers = [menuController,detailController]
        }
        let shelfNavController = createNavigationControllerWith(tabItem: .shelf, viewControllers: viewControllers)
        self.shelfNavigationController = shelfNavController
        return shelfNavController
    }
    func getContentTabItem() -> UIViewController {
        let mediaViewController = FTShelfCompactContentViewController()
        return createNavigationControllerWith(tabItem:.contents, viewControllers: [mediaViewController])
    }
    func getAddTabItem() -> UIViewController {
        return createNavigationControllerWith(tabItem: .addItem, viewControllers: [UIViewController()])
    }
    func getSearchTabItem() -> UIViewController {
        if let globalSearchController = UIStoryboard(name: "FTGlobalSearch", bundle: nil).instantiateViewController(identifier: "FTGlobalSearchController") as? FTGlobalSearchController {
            globalSearchController.shelfItemCollection = self.shelfItemCollection
            self.globalSearchVc = globalSearchController
            self.globalSearchVc?.delegate = globalSearchDelegate
        }
        return createNavigationControllerWith(tabItem: .search)
    }
    func getFavoritesTabItem() -> UIViewController {
        if let favoritedShelfItemCollection = FTNoteshelfDocumentProvider.shared.starredShelfItemCollection() {
            self.favoritesViewController = self.getSecondaryViewControllerWith(collection: favoritedShelfItemCollection, groupItem: nil)
        }
        return createNavigationControllerWith(tabItem: .favorites, viewControllers: [self.favoritesViewController ?? UIViewController()])
    }
    func createNavigationControllerWith(tabItem: FTPhoneModeTabBarItem, viewControllers: [UIViewController] = []) -> UINavigationController {
        let navController = FTNavigationController()
        navController.viewControllers = viewControllers
        navController.navigationBar.prefersLargeTitles = true
        navController.tabBarItem.title = tabItem.title
        navController.tabBarItem.image = tabItem.icon
        navController.tabBarItem.tag = tabItem.tag
        return navController
    }
    func getPrimaryViewController() -> FTSideMenuViewController {
        let sideBarViewModel = FTSidebarViewModel(collection:shelfItemCollection)
        sideBarViewModel.dropDelegate = self
        let sideMenuController = FTSideMenuViewController(viewModel: sideBarViewModel,shelfDisplayMenu: FTShelfMenuOverlayInfo())
        sideBarViewModel.delegate = sideMenuController
        sideMenuController.delegate = self
        return sideMenuController
    }
}
extension FTTabViewController: FTSideMenuViewControllerDelegate {
    func didCurrentCollectionRenamed(_ collection: FTShelfItemCollection) {

    }
    func showHomeView() {
        if let navigationController = self.viewControllers?.first as? UINavigationController {
            let shelfViewModel = FTShelfViewModel(sidebarItemType: .home)
            shelfViewModel.delegate = shelfViewModelDelegate
            shelfViewModel.tagsControllerDelegate = tagsControllerDelagate
            shelfViewModel.isSidebarOpen = false
            let detailViewController = FTShelfHomeViewController(shelfViewModel: shelfViewModel, shelfMenuOverlayInfo: FTShelfMenuOverlayInfo())
            detailViewController.title =  "Home"
            detailViewController.shelfViewModel = shelfViewModel
            navigationController.pushViewController(detailViewController, animated: true)
        }
    }

    func saveLastSelectedNonCollectionType(_ type: FTSideBarItemType) {
        // saving using shelf split function
    }

    func saveLastSelectedTag(_ tag: String) {
        // saving using shelf split function
    }

    func openBookmarks() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "FTShelfBookmarksViewController") as? FTShelfBookmarksViewController else {
            fatalError("FTShelfBookmarksViewController doesnt exist")
        }
        viewController.delegate = self
        if let navigationController = self.viewControllers?.first as? UINavigationController {
            navigationController.navigationBar.prefersLargeTitles = true
            navigationController.pushViewController(viewController, animated: true)
        }

    }

    func didTapOnUpgradeNow() {
        FTIAPurchaseHelper.shared.presentIAPIfNeeded(on: self);
    }

    func openTags(for tag: String, isAllTags: Bool) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "FTShelfTagsViewController") as? FTShelfTagsViewController else {
            fatalError("FTShelfTagsViewController doesnt exist")
        }
        viewController.delegate = self
        viewController.selectedTag = isAllTags ? nil : FTTagModel(text: tag);
        if let navigationController = self.viewControllers?.first as? UINavigationController {
            navigationController.navigationBar.prefersLargeTitles = true
            navigationController.pushViewController(viewController, animated: true)
        }
    }

    func showSettings() {
        let storyboard = UIStoryboard(name: "FTNewSettings", bundle: nil);
        if let settingsController = storyboard.instantiateViewController(withIdentifier: "FTGlobalSettingsController") as? FTGlobalSettingsController {
            let navController = UINavigationController(rootViewController: settingsController)
            navController.modalPresentationStyle = .formSheet
            self.present(navController, animated: true, completion: nil);
        }
    }

    func openPhotos() {

    }
    
    func openAudio() {

    }

    func emptyTrash(_ collection: FTShelfItemCollection, showConfirmationAlert: Bool, onCompletion: @escaping ((Bool) -> Void)) {

    }
    
    func saveLastSelectedCollection(_ collection: FTShelfItemCollection?) {

    }

    func showDetailedViewForCollection(_ collection: FTShelfItemCollection) {
        if let navigationController = self.viewControllers?.first as? UINavigationController {
            saveLastSelectedCollection(collection)
            self.shelfItemCollection = collection
            let detailViewController = getSecondaryViewControllerWith(collection: collection, groupItem: nil)
            detailViewController.title = collection.displayTitle
            navigationController.pushViewController(detailViewController, animated: true)
        }
    }

    func openTemplates() {
        let templatesStore = FTStoreContainerViewController.templatesStoreViewController(delegate: self,premiumUser: FTIAPManager.shared.premiumUser)
        if let navigationController = self.viewControllers?.first as? UINavigationController {
            navigationController.navigationBar.prefersLargeTitles = true
            navigationController.pushViewController(templatesStore, animated: true)
        }
    }
}
extension FTTabViewController: FTCategoryDropDelegate {
    func favoriteShelfItem(_ item: FTShelfItemProtocol, toPin: Bool) {
        FTNoteshelfDocumentProvider.shared.favoriteSelectedItems([item], isToPin: toPin, onController: self)
        if toPin {
            NotificationCenter.default.post(name: NSNotification.Name.shelfItemMakeFavorite, object: item, userInfo: nil)
        }
    }

    func moveDraggedShelfItem(_ item : FTShelfItemProtocol,
                              toCollection collection: FTShelfItemCollection,
                              onCompletion: @escaping (NSError?, [FTShelfItemProtocol]) -> Void){
        collection.moveShelfItems([item], toGroup: nil, toCollection: collection, onCompletion: { error, shelfItems in
            onCompletion(error, shelfItems)
        })
    }
    func endDragAndDropOperation() {
        self.currentShelfViewModel?.endDragAndDropOperation()
    }
}
extension FTTabViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController.tabBarItem.tag == 3 { // in case of add new notebook tab item, we are just presenting add new notebook view controller without selecting the tab item
            let shelfNewNoteViewModel = FTNewNotePopoverViewModel()
            shelfNewNoteViewModel.delegate = currentShelfViewModel
            let popOverHeight: CGFloat = 460
            let controller = FTShelfNewNoteController(viewModel: shelfNewNoteViewModel
                                                      , popOverHeight: popOverHeight
                                                      , appState:getSizeClass()
                                                      , shelfViewModel: currentShelfViewModel!
                                                      ,delegate: shelfNewNoteDelegate)
            controller.view.backgroundColor = .clear
            controller.ftPresentPopover(vcToPresent: controller, contentSize: CGSize(width: 330, height: popOverHeight))
            return false
        }
        return true
    }
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewController.tabBarItem.tag == 5 { // favorites tab
            self.favoritesViewController?.shelfViewModel.reloadShelf() // refreshing/refetching items whenever favorites tab is opened.
        } else if viewController.tabBarItem.tag == 4 {
            if let navVc = viewController as? FTNavigationController, let searchVc = self.globalSearchVc, !navVc.children.contains( where: { $0 is FTGlobalSearchController }) {
                navVc.pushViewController(searchVc, animated: false)
            }
        }
    }
    func getSizeClass() -> AppState {
        let appState = AppState(sizeClass: .regular)
        if let sizeClass = UserInterfaceSizeClass(self.traitCollection.horizontalSizeClass) {
            appState.sizeClass = sizeClass
        }
        return appState
    }
}

extension FTTabViewController: FTShelfTagsPageDelegate, FTShelfBookmarksPageDelegate {
    func openNotebook(shelfItem: FTShelfItemProtocol, page: Int) {

    }

    func openNotebook(shelfItem: FTDocumentItemProtocol, page: Int) {
        self.tagsDelegate?.openNotebook(shelfItem: shelfItem, page: page)
    }
}

// MARK: - FTStoreContainerDelegate
extension FTTabViewController: FTStoreContainerDelegate {
    func trackEvent(event: String, params: [String : Any]?, screenName: String?) {
        track(event, params: params, screenName: screenName)
    }

    func storeController(_ controller: UIViewController, menuShown isMenuShown: Bool) {
        if let splitContorller = controller.splitViewController as? FTShelfSplitViewController {
            splitContorller.shelfMenuDisplayInfo.isMenuShown = true;
        }
    }

    func createNotebookFor(url: URL, onCompletion: @escaping ((Error?) -> Void)) {

    }

    func createNotebookForTemplate(url: URL, isLandscape: Bool, isDark: Bool) {

    }

    func storeController(_ controller: UIViewController,showIAPAlert feature: String?) {
        if let inFeature = feature {
            FTIAPurchaseHelper.shared.showIAPAlertForFeature(feature: inFeature, on: controller);
        }
        else {
            FTIAPurchaseHelper.shared.showIAPAlert(on: controller);
        }
    }
    
    func createNotebookForDairy(fileName: String, title: String, startDate: Date, endDate: Date, coverImage: UIImage, isLandScape: Bool) {

    }

    func generatePDFFile(withImages images: [UIImage]) async -> URL? {
        return await withCheckedContinuation { continuation in
            FTPDFFileGenerator().generatePDFFile(withImages: images, onCompletion: {(filePath) in
                let requiredUrl = URL(fileURLWithPath: filePath)
                continuation.resume(returning: requiredUrl)
            })
        }
    }

    func convertFileToPDF(filePath: String) async throws -> URL? {
        return try await withCheckedThrowingContinuation({ continuation in
            FTFileImporter().convertFileToPDF(filePath: filePath) { path, error, isImageSource in
                if let error {
                    continuation.resume(throwing: error)
                } else if let path {
                    let requiredUrl = URL(fileURLWithPath: path)
                    continuation.resume(returning: requiredUrl)
                } else {
                    let error = NSError(domain: "com.ft.unknonwn", code: -100)
                    continuation.resume(throwing: error)
                }
            }
        })
    }
}
