//
//  ViewController.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 14/04/22.
//

import UIKit
import SwiftUI
import FTStyles
import Combine
import FTCommon

protocol FTSideMenuViewControllerDelegate: AnyObject {

    func showHomeView()
    func showDetailedViewForCollection(_ collection: FTShelfItemCollection)
    func didCurrentCollectionRenamed(_ collection: FTShelfItemCollection)
    func saveLastSelectedCollection(_ collection: FTShelfItemCollection?)
    func emptyTrash(_ collection : FTShelfItemCollection, showConfirmationAlert: Bool,onCompletion: @escaping ((Bool) -> Void))
    func saveLastSelectedNonCollectionType(_ type: FTSideBarItemType)

    // Templates
    func openTemplates()

    //Media Content
    func openPhotos()
    func openAudio()

    //Bookmarks, tags
    func openBookmarks()
    func openTags(for tag: String, isAllTags: Bool)
    func saveLastSelectedTag(_ tag:String)
    
    // Global search
    func didTapOnCategoriesOverlay()

    //settings
    func showSettings()
    func didTapOnUpgradeNow();
    func didTapDownloadBooks()
}

extension FTSideMenuViewControllerDelegate {
    // Global search
    func didTapOnCategoriesOverlay() {
        debugPrint("Implement for compact mode if required only")
    }
}

class FTSideMenuViewController: UIHostingController<AnyView> {
    private var cancellables = [AnyCancellable]()
    private weak var viewModel : FTSidebarViewModel!
    weak var delegate: FTSideMenuViewControllerDelegate?
    var overLayBg: UIView?

    init(viewModel: FTSidebarViewModel, shelfDisplayMenu: FTShelfMenuOverlayInfo) {
        self.viewModel = viewModel
        super.init(rootView: AnyView(FTSidebarView().environmentObject(shelfDisplayMenu).environmentObject(FTIAPManager.shared.premiumUser).environmentObject(viewModel)))
        self.viewModel.delegate = self
        self.title = "Noteshelf";
        self.navigationItem.backButtonDisplayMode = .minimal;
    }

    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func instantiateFromStroyboard() -> FTSideMenuViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "FTSideMenuViewController") as? FTSideMenuViewController else {
            fatalError("FTSideMenuViewController doesnt exist")
        }
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.appColor(.sidebarBG)
        self.addOverlay()
        self.setUpNavigationBar()
        viewModel.addNotificationObservers()
    }

    deinit {
        disableUpdatesForSideBar()
    }

    func addBlurView() {
        runInMainThread {
            self.overLayBg?.isHidden = false
            self.overLayBg?.alpha = 0.0
            UIView.animate(withDuration: 0.3, animations: {
                self.overLayBg?.alpha = 0.2
            }) { (_) in
            }
        }
    }

    func removeBlurView() {
        UIView.animate(withDuration: 0.15, animations: {
            self.overLayBg?.alpha = 0.0
        }) { (_) in
            self.overLayBg?.isHidden = true
        }
    }

    func upateSideMenuCurrentCollection(_ collection: FTShelfItemCollection) {
        if self.viewModel.selectedShelfItemCollection?.uuid != collection.uuid {
            self.viewModel.selectedShelfItemCollection = collection
        }
    }

    func selectSidebarItemWithCollection(_ shelfItemCollection: FTShelfItemCollection) {
        self.viewModel.selectSidebarItemWithCollection(shelfItemCollection)
    }
    func showSidebarItemWithCollection(_ shelfItemCollection: FTShelfItemCollection){
        self.viewModel.showSidebarItemWithCollection(shelfItemCollection)
    }
    func updateSideMenuItemsCollections(){ // Use this method to force update sidebar's categories sections related collections
        viewModel.updateUserCreatedCategories()
    }

    private func addOverlay() {
        overLayBg = UIView()
        overLayBg?.alpha = 0.0
        overLayBg?.frame = self.view.bounds
        overLayBg?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overLayBg?.backgroundColor = .black
        if let overLayBg = overLayBg {
            self.view.addSubview(overLayBg)
        }
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.handleTapOnOverlay))
        self.overLayBg?.addGestureRecognizer(tapGesture)
    }

    @objc private func handleTapOnOverlay() {
        self.delegate?.didTapOnCategoriesOverlay()
    }

    func selectAndOpenTemplatesScreen() {
        if let barItem = self.viewModel.menuItems.flatMap({$0.items}).first(where: {$0.type == .templates}) {
            self.viewModel.selectedSideBarItem = barItem
            self.delegate?.openTemplates()
        }
    }
    func setSideBarWidthTo(_ width: CGFloat) {
        self.viewModel.sideBarItemWidth = width
    }

    func didSelectBarItem(_ item: FTSideBarItem) {
        let currentCollection = item.shelfCollection ??  FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection
        switch item.type {
        case .home:
            delegate?.showHomeView()
        case .unCategorized,.trash,.starred:
            delegate?.showDetailedViewForCollection(currentCollection)
        case .templates:
            delegate?.openTemplates()
        case .category,.ns2Category,.addnewCategory:
            delegate?.showDetailedViewForCollection(currentCollection)
        case .media:
            delegate?.openPhotos()
        case .audio:
            delegate?.openAudio()
        case .tag:
            delegate?.openTags(for: item.title, isAllTags: false)
        case .bookmark:
            delegate?.openBookmarks()
        case .allTags:
            delegate?.openTags(for: item.title, isAllTags: true)
        }
    }

    private func setUpNavigationBar(){
        self.title = "Noteshelf"
        if let navigationController = self.navigationController {
            navigationController.navigationBar.prefersLargeTitles = true
            navigationController.navigationBar.tintColor = UIColor.appColor(.accent)
            let attributes :  [NSAttributedString.Key : Any] = [.font : UIFont.clearFaceFont(for: .medium, with: 28)]
            navigationController.navigationBar.largeTitleTextAttributes = attributes
        }
    }
    
    func enableUpdatesForSideBar() {
        viewModel.addNotificationObservers()
    }
    
    func disableUpdatesForSideBar() {
        viewModel.removeNotificationObservers()
    }
}

extension FTSideMenuViewController: FTSidebarViewDelegate {
    func didTapOnSettings() {
        self.delegate?.showSettings()
    }

    func didTapOnUpgradeNow() {
        self.delegate?.didTapOnUpgradeNow()
        track(EventName.sidebar_premium_tap, screenName: ScreenName.sidebar)
    }
    
    func didTapDownloadBooks() {
        self.delegate?.didTapDownloadBooks()
    }
    
    func emptyTrash(_ collection: FTShelfItemCollection, showConfirmationAlert: Bool, onCompletion: @escaping ((Bool) -> Void)) {
        self.delegate?.emptyTrash(collection, showConfirmationAlert: showConfirmationAlert, onCompletion: onCompletion)
    }
    func didTapOnSidebarItem(_ item: FTSideBarItem) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector:#selector(self.handleSidebarSelection), object: nil);
        self.perform(#selector(self.handleSidebarSelection), with: nil, afterDelay: 0.2);
        track(eventNameFor(item: item), screenName: ScreenName.sidebar)
    }
    
    @objc func handleSidebarSelection() {
        guard let item: FTSideBarItem = viewModel.selectedSideBarItem else {
            return;
        }
        let nonCollectionTypes: [FTSideBarItemType] = [.templates,.media,.bookmark,.audio,.tag,.home]
        if nonCollectionTypes.contains(where: { $0 == item.type}) {
            self.delegate?.saveLastSelectedNonCollectionType(item.type)
            if item.type == .tag {
                self.delegate?.saveLastSelectedTag(item.title)
            }
        } else {
            self.delegate?.saveLastSelectedCollection(item.shelfCollection)
        }
        self.didSelectBarItem(item)
    }
    
    func didSidebarItemRenamed(_ item: FTSideBarItem) {
        if item.type == .category,let collection = item.shelfCollection {
            self.delegate?.didCurrentCollectionRenamed(collection)
        }
    }

    private func eventNameFor(item: FTSideBarItem) -> String {
        let eventMapping: [FTSideBarItemType: String] = [
            .home: EventName.sidebar_home_tap,
            .templates: EventName.sidebar_templates_tap,
            .unCategorized: EventName.sidebar_unflied_tap,
            .trash: EventName.sidebar_trash_tap,
            .category: EventName.sidebar_category_tap,
            .starred: EventName.sidebar_starred_tap,
            .media: EventName.sidebar_photo_tap,
            .audio: EventName.sidebar_recording_tap,
            .bookmark: EventName.sidebar_bookmark_tap
        ]

        if let event = eventMapping[item.type] {
            return event
        }

        if item.type == .tag {
            if item.title == "shelf.sidebar.allTags".localized {
                return EventName.sidebar_alltags_tap
            } else {
                return EventName.sidebar_tag_tap
            }
        }
        return ""
    }

}
