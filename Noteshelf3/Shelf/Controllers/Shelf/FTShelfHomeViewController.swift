//
//  FTShelfHomeViewController.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 02/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class FTShelfHomeViewController: FTShelfBaseHostingController {
    private var cancellables = [AnyCancellable]()
    private var cancellables1 = [AnyCancellable]()
    private var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo;
    
    required init(shelfViewModel model: FTShelfViewModel, shelfMenuOverlayInfo info: FTShelfMenuOverlayInfo) {
        shelfMenuOverlayInfo = info;
        super.init(rootView: AnyView(FTShelfHomeView().environmentObject(model).environmentObject(info)));
        self.shelfViewModel = model;
    }

    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.shelfViewModel.didTapOnSeeAllNotes = { [weak self] in
            self?.didTapOnSeeAllNotes()
        }
    }
}

private extension FTShelfHomeViewController {
   private func didTapOnSeeAllNotes() {
        let newShelfViewModel = FTShelfViewModel(collection: FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection, groupItem: nil)
        newShelfViewModel.delegate = self.shelfViewModel.delegate
        newShelfViewModel.tagsControllerDelegate = self.shelfViewModel.tagsControllerDelegate
        newShelfViewModel.isSidebarOpen = self.splitViewController?.displayMode == .oneBesideSecondary
        let newShelfViewController = FTShelfViewControllerNew(shelfViewModel: newShelfViewModel,shelfMenuOverlayInfo: shelfMenuOverlayInfo)
        newShelfViewController.shelfViewModel = newShelfViewModel
        newShelfViewController.shelfItemCollection = FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection
        newShelfViewController.title = NSLocalizedString("AllNotes", comment: "All Notes")
        self.navigationController?.pushViewController(newShelfViewController, animated: true)
    }
}
