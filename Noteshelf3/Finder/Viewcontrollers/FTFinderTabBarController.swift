//
//  FTFinderTabBarController.swift
//  Noteshelf3
//
//  Created by Sameer on 21/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

enum FTFinderSelectedTab: Int {
    case thumnails
    case content
    case search
}

protocol FTFinderTabBarDelegate {
    func didTapOnExpandButton()
    func didTapOnDismissButton()
    func currentScreenMode() -> FTFinderScreenMode
    func _isRegularClass() -> Bool
}

class FTFinderTabBarController: UITabBarController, FTFinderPresentable, FTCustomPresentable {
    var customTransitioningDelegate = FTCustomTransitionDelegate(with: .interaction, supportsFullScreen: true)
    var screenMode: FTFinderScreenMode = .normal {
        didSet {
            self.childVcDelegate?.screenModeDidChange()
        }
    }
    weak var childVcDelegate: FTFinderTabBarProtocol?
    var isResizing: Bool = false
    var currentDisplayMode: UISplitViewController.DisplayMode?
    weak var splitVc: FTNoteBookSplitViewController?
    weak var finderDelegate: FTFinderThumbnailsActionDelegate?
    var finderTransitioningDelegate: FTFinderTransitionDelegate = FTFinderTransitionDelegate(with: .defaultAnimation, direction: .leftToRight)
    
    deinit {
        self.splitVc = nil
    }
    
    override var shouldAvoidDismissOnSizeChange: Bool {
        return true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        var toHide: Bool = true
        if UIDevice.current.isPhone() {
            toHide = false
        }
        return toHide
    }
    
    override var prefersStatusBarHidden: Bool {
        return self.prefersHomeIndicatorAutoHidden;
    }
    
    func didChangeState(to screenState: FTFinderScreenState) {
        let selectedIndex = self.selectedIndex
        let currentVc = self.viewControllers?[selectedIndex]
        if selectedIndex >= 0, let currentVc = currentVc as? FTFinderTabBarProtocol {
            currentVc.didChangeState(to: screenState)
        } else if let currentVc = currentVc, currentVc is UINavigationController, currentVc.children.count >= 0, let vc = currentVc.children[0] as? FTFinderTabBarProtocol{
            vc.didChangeState(to: screenState)
        }
        splitVc?.presentsWithGesture = true
//        if screenState == .initial && traitCollection.isRegular {
        if screenState == .dragging && traitCollection.isRegular && screenMode == .normal {
            self.dismiss(animated: false) { [weak self] in
                guard let self = self else {
                  return
                }
                self.splitVc?.addSupplimentaryController(self)
            }
        }
        if screenState == .fullScreen {
            if screenMode == .normal {
                self.screenMode = .fullScreen
                self.finderTransitioningDelegate = FTFinderTransitionDelegate(with: .presentWithoutAnimation, direction: .leftToRight, splitMode: finderSplitMode())
                self.splitVc?.presentFinderHorizontally(self, animated: true, completion: nil)
                self.splitVc?.preferredDisplayMode = self.currentDisplayMode ?? .secondaryOnly
            }
        }
        else if screenState == .initial {
                screenMode = . normal
        } else if screenState == .dismiss {
            // compact mode dismiss
            self.splitVc?.addSupplimentaryController(self)
        }
    }
    
    func detectTraitCollectionDidChange(to traitCollection: UITraitCollection) {
        if UIApplication.shared.applicationState == .background {
            return
        }
        if !traitCollection.isRegular {
           self.dismiss(animated: false) { [weak self] in
               guard let self = self else {
                 return
               }
               self.screenMode = .normal
               self.splitVc?.addSupplimentaryController(self)
               self.splitVc?.preferredDisplayMode = self.currentDisplayMode ?? .secondaryOnly
               self.splitVc?.presentsWithGesture = false
               self.customTransitioningDelegate = FTCustomTransitionDelegate(with: .interaction, supportsFullScreen: true, shouldStartWithFullScreen: true)
                   self.modalPresentationStyle = .formSheet
               self.splitVc?.ftPresentModally(self,contentSize: self.view.frame.size, animated: true, completion: nil)
               NotificationCenter.default.post(name: .validationFinderButtonNotification, object: self.splitVc?.view.window)
           }
        } else {
            self.dismiss(animated: false) { [weak self] in
                guard let self = self else {
                  return
                }
                self.screenMode = .fullScreen
                self.splitVc?.preferredDisplayMode = self.currentDisplayMode ?? .secondaryOnly
                self.finderTransitioningDelegate = FTFinderTransitionDelegate(with: .presentWithoutAnimation, direction: .leftToRight, splitMode: self.finderSplitMode())
                self.splitVc?.presentFinderHorizontally(self, animated: true, completion: nil)
            }
        }
    }

    func shouldStartWithFullScreen() -> Bool {
        return UserDefaults.standard.bool(forKey: "FT_Thumbnails_FullScreen")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTabBarImages()
        applyTabBarAppearance()
#if targetEnvironment(macCatalyst)
        self.configureForMac();
#endif
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
    }
    
    class func viewController(delegate : FTFinderTabBarDelegate?, with doc: FTDocumentProtocol, mode: FTFinderScreenMode = .normal, searchOptions: FTFinderSearchOptions) -> FTFinderTabBarController
    {
        let finderTabBar = FTFinderTabBarController.instantiate(fromStoryboard: .finder)
        if  let controllers = finderTabBar.viewControllers {
            for (index, eachVc) in controllers.enumerated() {
                if var vc = eachVc as? FTFinderTabBarProtocol {
                    vc.configureData(forDocument: doc as! FTThumbnailableCollection, exportInfo: nil, delegate: finderTabBar, searchOptions: searchOptions)
                    vc.selectedTab = finderTabBar.tabFor(index: index)
                } else if eachVc is UINavigationController, eachVc.children.count >= 0, var vc = eachVc.children[0] as? FTFinderTabBarProtocol {
                    vc.configureData(forDocument: doc as! FTThumbnailableCollection, exportInfo: nil, delegate: finderTabBar, searchOptions: searchOptions)
                    vc.selectedTab = finderTabBar.tabFor(index: index)
                }
            }
        }
        return finderTabBar;
    }
    
    private func setTabBarImages() {
        for (idx, tabBarItem) in tabBar.items!.enumerated() {
            let configuration = UIImage.SymbolConfiguration(font: UIFont.appFont(for: .regular, with: 17))
            if idx == 0 {
                tabBarItem.tag = 0
                tabBarItem.title = "Pages".localized
                tabBarItem.image = UIImage(systemName: "doc", withConfiguration: configuration)
                tabBarItem.selectedImage = UIImage(systemName: "doc.fill", withConfiguration: configuration)
            } else if idx == 1 {
                tabBarItem.tag = 1
                tabBarItem.title = "finder.tabbar.content".localized
                tabBarItem.image = UIImage(systemName: "photo.fill.on.rectangle.fill", withConfiguration: configuration)
                tabBarItem.selectedImage = UIImage(systemName: "photo.fill.on.rectangle.fill", withConfiguration: configuration)
            } else if idx == 2 {
                tabBarItem.tag = 2
                tabBarItem.title = "Search".localized
                tabBarItem.image = UIImage(systemName: "magnifyingglass", withConfiguration: configuration)
                tabBarItem.selectedImage = UIImage(systemName: "magnifyingglass", withConfiguration: configuration)
            }
        }
    }
    
    private func applyTabBarAppearance() {
        let appearance = UITabBarAppearance()
        let selectedTitleAttrs = [NSAttributedString.Key.font : UIFont.appFont(for: .semibold, with: 10), NSAttributedString.Key.foregroundColor : UIColor.appColor(.accent)]
        let normalTitlteAttrs = [NSAttributedString.Key.font : UIFont.appFont(for: .semibold, with: 10), NSAttributedString.Key.foregroundColor : UIColor.appColor(.black70)]
        let selectedIconColor = UIColor.appColor(.accent)
        let normalIconColor = UIColor.appColor(.black70)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedTitleAttrs
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalTitlteAttrs
        appearance.stackedLayoutAppearance.normal.iconColor = normalIconColor
        appearance.stackedLayoutAppearance.selected.iconColor = selectedIconColor
        applyInlineBarAppearance(appearance: appearance)
        self.tabBar.standardAppearance = appearance
        self.tabBar.scrollEdgeAppearance = appearance
    }
    
    private func applyInlineBarAppearance(appearance: UITabBarAppearance) {
        let selectedTitleAttrs = [NSAttributedString.Key.foregroundColor : UIColor.appColor(.accent)]
        let normalTitlteAttrs = [NSAttributedString.Key.foregroundColor : UIColor.appColor(.black70)]
        let selectedIconColor = UIColor.appColor(.accent)
        let normalIconColor = UIColor.appColor(.black70)
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = selectedTitleAttrs
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = normalTitlteAttrs
        appearance.inlineLayoutAppearance.normal.iconColor = normalIconColor
        appearance.inlineLayoutAppearance.selected.iconColor = selectedIconColor
    }
    
    private func tabFor(index: Int) -> FTFinderSelectedTab {
        var selectedTab = FTFinderSelectedTab.thumnails
        if index == 0 {
            selectedTab = .thumnails
        } else if index == 1  {
            selectedTab = .content
        } else if index == 2 {
            selectedTab = .search
        }
        return selectedTab
    }
    
    func didTapOnPrimaryButton() {
        if let splitVc = self.splitViewController {
            let displayMode = splitVc.displayMode
            if displayMode == .oneBesideSecondary || displayMode == .oneOverSecondary {
                splitVc.show(.primary)
            } else {
                splitVc.hide(.primary)
            }
        }
    }
    
    func didTapOnFinderCloseButton() {
        if screenMode == .normal {
            if let splitVc = self.splitViewController {
                var displayMode = splitVc.displayMode
                if displayMode == .oneBesideSecondary || displayMode == .oneOverSecondary || displayMode == .twoOverSecondary {
                    displayMode = .secondaryOnly
                    splitVc.preferredSplitBehavior = .automatic
                    self.noteBookSplitViewController()?.curentPrefrredDisplayMode = .secondaryOnly
                } else if displayMode == .twoBesideSecondary || displayMode == .twoDisplaceSecondary {
                    displayMode = .oneBesideSecondary
                }
                UIView.animate(withDuration: 0.2) {
                    splitVc.preferredDisplayMode = displayMode
                    NotificationCenter.default.post(name: .validationFinderButtonNotification, object: self.view.window)
                }
            }
        } else if screenMode == .fullScreen {
             self.didTapOnExpandButton()
        }
    }
}

extension FTFinderTabBarController: FTFinderThumbnailsActionDelegate {
    func didInsertPageFromFinder(_ item: FTPageType) {
        self.finderDelegate?.didInsertPageFromFinder(item)
    }
    
    func currentPage(in finderViewController: FTFinderViewController) -> FTThumbnailable? {
        return self.finderDelegate?.currentPage(in: finderViewController)
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectInsertAboveForPage page: FTPageProtocol?) {
        self.finderDelegate?.finderViewController(finderViewController, didSelectInsertAboveForPage: page)
    }

    func finderViewController(bookMark page: FTThumbnailable) {
        self.finderDelegate?.finderViewController(bookMark: page)
    }

    func finderViewController(didSelectDuplicate pages: [FTThumbnailable], onCompletion: (()->())?) {
        self.finderDelegate?.finderViewController(didSelectDuplicate: pages, onCompletion: onCompletion)
    }

    func finderViewController(_ finderVc: FTFinderViewController, didSelectTag pages: NSSet, from source: UIView) {
        self.finderDelegate?.finderViewController(finderVc, didSelectTag: pages, from: source)
    }

    func finderViewController(_ finderViewController: FTFinderViewController, didSelectInsertBelowForPage page: FTPageProtocol?) {
        self.finderDelegate?.finderViewController(finderViewController, didSelectInsertBelowForPage: page)
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectRemovePagesWithIndices indices: IndexSet) {
        self.finderDelegate?.finderViewController(finderViewController, didSelectRemovePagesWithIndices: indices)
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectPages pages: NSSet, toMoveTo shelfItem: FTShelfItemProtocol) {
        self.finderDelegate?.finderViewController(finderViewController, didSelectPages: pages, toMoveTo: shelfItem)
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectShareWithPages pages: NSSet, exportTarget: FTExportTarget?) {
        self.finderDelegate?.finderViewController(finderViewController, didSelectShareWithPages: pages, exportTarget: exportTarget)
    }
    
    func shouldShowMoveOperation(in finderViewController: FTFinderViewController) -> Bool {
        return self.finderDelegate?.shouldShowMoveOperation(in: finderViewController) ?? false
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didMovePageAtIndex fromIndex: Int, toIndex: Int) {
        self.finderDelegate?.finderViewController(finderViewController, didMovePageAtIndex: fromIndex, toIndex: toIndex)
    }
    
    func finderViewController(_ contorller: FTFinderViewController, searchForKeyword searchKey: String, onFinding: (() -> ())?, onCompletion: (() -> ())?) {
        self.finderDelegate?.finderViewController(contorller, searchForKeyword: searchKey, onFinding: onFinding, onCompletion: onCompletion)
    }
    
    func finderViewController(didSelectPageAtIndex index: Int) {
        self.finderDelegate?.finderViewController(didSelectPageAtIndex: index)
        self.didTapOnItem()
    }
    
    func cancelFinderSearchOperation() {
        self.finderDelegate?.cancelFinderSearchOperation()
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, didSelectRotatePages pages: NSSet) {
        self.finderDelegate?.finderViewController(finderViewController, didSelectRotatePages: pages)
    }
    
    func finderViewController(_ finderViewController: FTFinderViewController, pastePagesAtIndex index: Int?) {
        self.finderDelegate?.finderViewController(finderViewController, pastePagesAtIndex: index)
    }
    
    func currentShelfItemInShelfItemsViewController() -> FTShelfItemProtocol? {
        return self.finderDelegate?.currentShelfItemInShelfItemsViewController()
    }
    
    func currentGroupShelfItemInShelfItemsViewController() -> FTGroupItemProtocol? {
        return self.finderDelegate?.currentGroupShelfItemInShelfItemsViewController()
    }
    
    func currentShelfItemCollectionInShelfItemsViewController() -> FTShelfItemCollection? {
        return self.finderDelegate?.currentShelfItemCollectionInShelfItemsViewController()
    }
}

extension FTFinderTabBarController: FTFinderTabBarDelegate {
    func didTapOnExpandButton() {
        if self.screenMode == .fullScreen {
            screenMode = .normal
            if let vc = self.parent as? UINavigationController
                ,let prtController = vc.presentationController as? FTFinderPresentationController {
                if !self.shouldStartWithFullScreen() && self.splitVc?.preferredDisplayMode  == .secondaryOnly {
                    if !UIDevice.isLandscapeOrientation && self.splitVc?.preferredSplitBehavior != .displace {
                        self.splitVc?.preferredSplitBehavior = .displace
                    }
                    self.splitVc?.preferredDisplayMode = .oneBesideSecondary
                    self.splitVc?.curentPrefrredDisplayMode = .oneBesideSecondary
                }
                prtController.mode = finderSplitMode()
                prtController.endScreenStateToInitial(to: .initial);
            }
        } else {
            self.splitVc = self.noteBookSplitViewController()
            self.screenMode = .fullScreen
            currentDisplayMode = splitVc?.displayMode
            self.finderTransitioningDelegate = FTFinderTransitionDelegate(with: .presentWithoutAnimation, direction: .leftToRight, splitMode: finderSplitMode())
            self.splitVc?.presentFinderHorizontally(self, animated: true, completion: {
            })
        }
        NotificationCenter.default.post(name: .validationFinderButtonNotification, object: self.view.window)
    }
    
    func didTapOnCloseButton() {
        self.splitVc?.preferredDisplayMode = .secondaryOnly
        self.splitVc?.curentPrefrredDisplayMode = .secondaryOnly
        self.shouldStartWithFullScreen(true)
        self.splitVc?.preferredSplitBehavior = .automatic
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else {
                return
            }
            self.screenMode = .normal
            self.splitVc?.addSupplimentaryController(self)
        }
    }
    
    func shouldStartWithFullScreen(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: "FT_Thumbnails_FullScreen")
        UserDefaults.standard.synchronize();
    }
    
    func presentFinder() {
        self.splitVc = self.noteBookSplitViewController()
        self.screenMode = .fullScreen
        currentDisplayMode = splitVc?.displayMode
        self.finderTransitioningDelegate = FTFinderTransitionDelegate(with: .defaultAnimation, direction: .leftToRight, splitMode: finderSplitMode())
        self.splitVc?.presentFinderHorizontally(self, animated: true, completion: {
        })
    }
    
    func didTapOnDismissButton() {
        self.dismiss(animated: true) {[weak self] in
            guard let self = self else{
                return
            }
            self.splitVc?.addSupplimentaryController(self)
        }
    }
    
    private func didTapOnItem() {
        if !self._isRegularClass() {
            self.didTapOnDismissButton()
        } else {
            if screenMode == .fullScreen {
                self.didTapOnCloseButton()
            } else {
                if self.splitViewController?.displayMode == .oneOverSecondary || self.splitViewController?.displayMode == .twoOverSecondary {
                    self.splitViewController?.preferredDisplayMode = .secondaryOnly
                    self.splitVc?.curentPrefrredDisplayMode = .secondaryOnly
                }
            }
        }
    }
    
    func currentScreenMode() -> FTFinderScreenMode{
        return screenMode
    }
    
    func _isRegularClass() -> Bool {
        var isRegular = super.isRegularClass()
        if let splitVc = self.splitViewController {
            isRegular = splitVc.isRegularClass()
        }
        return isRegular
    }

    private func finderSplitMode() -> FTFinderMode {
        var finderMode = FTFinderMode.sideBySide
        if let splitVc = splitVc  {
            let displayMode = splitVc.displayMode
            switch displayMode {
            case .oneBesideSecondary:
                finderMode = .sideBySide
            case .oneOverSecondary:
                finderMode = .suplimentaryOverlay
            case .twoOverSecondary:
                finderMode = .primaryOverlay
            case .twoDisplaceSecondary:
                finderMode = .twoBesideSecondary
            default:
                finderMode = .sideBySide
            }
        }
        return finderMode
    }
}

extension FTFinderTabBarController: FTFinderNotifier {
    func didAddPage() {
        self.reloadDataIfNeeded()
    }

    func didBookmarkPage() {
        self.reloadDataIfNeeded()
    }

    func willEnterIntoEditmode() {
        if let finderVc = self.children.filter({ vc in
            vc is FTFinderViewController
        }).first as? FTFinderViewController {
            finderVc.switchToEditModeIfNeeded()
        }
    }
    
    func didGoToAudioRecordings(with annotation: FTAnnotation) {
        if self.splitViewController?.displayMode == .oneBesideSecondary {
            self.selectedIndex = 1
        } else if self.splitViewController?.displayMode == .secondaryOnly {
            UIView.animate(withDuration: 0.2) {
                self.splitViewController?.preferredDisplayMode = .oneOverSecondary
                self.selectedIndex = 1
            }
        }
    }

    func didTagPage() {
        self.reloadDataIfNeeded()
    }

    func didRotatePage() {
        self.reloadDataIfNeeded()
    }

    func didDuplicatePage() {
        self.reloadDataIfNeeded()
    }

   private func reloadDataIfNeeded() {
        if let finderVc = self.children.filter({ vc in
            vc is FTFinderViewController
        }).first as? FTFinderViewController, finderVc.isViewLoaded {
            finderVc.reloadData()
        }
    }
}

#if targetEnvironment(macCatalyst)
extension FTFinderTabBarController {
    func configureForMac() {
        self.tabBar.isHidden = true;
        self.viewControllers?.forEach({ eachController in
            if let navController = eachController as? UINavigationController {
                if !(navController.viewControllers[0] is FTFinderSearchController) {
                    navController.setNavigationBarHidden(true, animated: false);
                }
            }
        })
    }
    
    func showFinderContent(_ type: FTNotebookSidebarMenuType) {
        if(
            type == .thumbnails
            || type == .bookmarks
            || type == .tableOfContents
        ) {
            if(self.tabFor(index: self.selectedIndex) != .thumnails) {
                self.selectedIndex = FTFinderSelectedTab.thumnails.rawValue;
            }
            if let navController = self.selectedViewController as? UINavigationController,
               let finderController = navController.viewControllers[0] as? FTFinderViewController {
                finderController.showContent(type);
            }
        }
        else if(type == .mediaContent) {
            if(self.tabFor(index: self.selectedIndex) != .content) {
                self.selectedIndex = FTFinderSelectedTab.content.rawValue;
            }
        }
        else if(type == .search) {
            if(self.tabFor(index: self.selectedIndex) != .content) {
                self.selectedIndex = FTFinderSelectedTab.search.rawValue;
            }
        }
    }
}
#endif
