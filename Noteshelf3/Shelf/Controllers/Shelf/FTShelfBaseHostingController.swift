//
//  FTShelfBaseViewControllerNew.swift
//  Noteshelf3
//
//  Created by Narayana on 29/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import Combine

class FTShelfBaseHostingController: UIHostingController<AnyView> {
    var shelfViewModel: FTShelfViewModel!
    private var cancellables = [AnyCancellable]()
#if targetEnvironment(macCatalyst)
    weak var delegate: FTMacGlobalSearchDelegate?
    var selectNoteCancellable = [AnyCancellable]()
#endif

    override init(rootView: AnyView) {
        super.init(rootView: rootView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
#if targetEnvironment(macCatalyst)
        if let toolbar = self.splitViewController?.view.toolbar as? FTShelfToolbar {
            self.observeShelfModelChanges(of: toolbar)
        }
#endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchShelfItems()
        self.updateSelectionIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateBottomToolBarCompactStatus()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.shelfViewModel.removeObserversForShelfItems()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
        }
    }

    override func didMove(toParent parent: UIViewController?) {
        if parent == nil {
            self.removeFromParent()
        }
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension FTShelfBaseHostingController {
    private func setupView(){
        self.view.backgroundColor = UIColor.appColor(.shelfViewBG)
        self.styleNavigationBar()
        self.addSelectionModeChangeListener()
    }

    private func updateSelectionIfNeeded() {
        if let splitController = self.splitViewController as? FTShelfSplitViewController {
            splitController.shelfItemCollection = shelfViewModel.collection
            splitController.sideMenuController?.selectSidebarItemWithCollection(shelfViewModel.collection)
        }
    }

    private func showOrHideOverlayOnSideBar(_ hide: Bool) {
        if self.traitCollection.isRegular, let sideMenuVc = self.splitViewController?.viewController(for: .primary)?.children.first(where: { controller in
            controller is FTSideMenuViewController // sidebar will be visible along with shelf only when traitCollection is regular, so adding/removing blur in that mode only.
        }) as? FTSideMenuViewController {
            if hide {
                sideMenuVc.removeBlurView()
            } else {
                sideMenuVc.addBlurView()
            }
        }
    }

    private func addSelectionModeChangeListener() {
        self.shelfViewModel.$mode
            .dropFirst()
            .sink { [weak self] mode in
                guard let self = self else { return }
                if mode == .selection {
                    self.showOrHideOverlayOnSideBar(false)
                    self.navigationController?.isToolbarHidden = false
                }else {
                    self.showOrHideOverlayOnSideBar(true)
                    self.navigationController?.isToolbarHidden = true
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateBottomToolBarCompactStatus(){
        if isInLandscape {
            self.shelfViewModel.showCompactBottombar = (!self.traitCollection.isRegular && self.splitViewController?.displayMode == .oneBesideSecondary)
        } else {
            self.shelfViewModel.showCompactBottombar = ((self.splitViewController?.displayMode == .oneBesideSecondary && self.traitCollection.isRegular && !isInLandscape) || !self.traitCollection.isRegular)
        }
    }

    private func styleNavigationBar(){
        if let navigationController = self.navigationController {
            navigationController.navigationBar.prefersLargeTitles = true
            navigationController.navigationBar.tintColor = UIColor.appColor(.accent)
            let attributes :  [NSAttributedString.Key : Any] = [.font : UIFont.clearFaceFont(for: .medium, with: 36)]
            navigationController.navigationBar.largeTitleTextAttributes = attributes
        }
    }

    private func fetchShelfItems(){
        shelfViewModel.fetchShelfItems()
    }
}
