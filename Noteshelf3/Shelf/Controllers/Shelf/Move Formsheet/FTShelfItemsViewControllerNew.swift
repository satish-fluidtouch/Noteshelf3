//
//  FTShelfItemsViewControllerNew.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 21/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI
import FTCommon

class FTShelfItemsViewControllerNew: UIHostingController<FTShelfItemsView>, FTPopoverPresentable {
    var ftPresentationDelegate: FTPopoverPresentation = FTPopoverPresentation()

    private var shelfItemsViewModel: FTShelfItemsViewModel
    private var purpose: FTShelfItemsPurpose = .shelf
    var customTransitioningDelegate = FTCustomTransitionDelegate(with: .interaction, supportsFullScreen: false);

    weak var delegate: FTDocumentSelectionDelegate?
    
    init(shelfItemsViewModel: FTShelfItemsViewModel, purpose: FTShelfItemsPurpose, delegate: FTDocumentSelectionDelegate? = nil) {
        self.shelfItemsViewModel = shelfItemsViewModel
        self.purpose = purpose
        self.delegate = delegate
        let view = FTShelfItemsView(viewModel: shelfItemsViewModel,purpose: purpose)
        super.init(rootView: view)
        self.rootView.viewDelegate = self
    }

    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.appColor(.formSheetBgColor)
        self.shelfItemsViewModel.presentedViewController = self
        self.styleNavigationBar()
    }
    private func styleNavigationBar(){
        if let navigationController = self.navigationController {
            navigationController.navigationBar.tintColor = UIColor.appColor(.accent)
        }
    }
}
extension FTShelfItemsViewControllerNew: FTShelfItemsViewDelegate {
    func didSelectShelfItem(_ item: FTShelfItemProtocol) {
        self.delegate?.didSelect(document: item)
    }

    func dismisspopover() {
        self.dismiss(animated: true)
    }
    func openShelfItemsOf(collection: FTShelfItemCollection?, group: FTGroupItemProtocol?) {
        let shelfItemsViewModel = self.getShelfItemsViewModelFor(collection: collection, group: group)
        let controller = FTShelfItemsViewControllerNew(shelfItemsViewModel: shelfItemsViewModel, purpose: purpose, delegate: self.delegate)
        if group != nil {
            controller.title =  group?.displayTitle ?? ""
        } else if collection != nil {
            controller.title =  collection?.displayTitle ?? ""
        }
        self.navigationController?.pushViewController(controller, animated: true)
    }
    private func getShelfItemsViewModelFor(collection: FTShelfItemCollection?, group: FTGroupItemProtocol?)-> FTShelfItemsViewModel{
        let shelfItemsViewModelNew = FTShelfItemsViewModel(selectedShelfItems: shelfItemsViewModel.selectedShelfItemsForMove,collection: collection, groupItem: group,purpose: purpose)
        shelfItemsViewModelNew.delegate = shelfItemsViewModel.delegate
        shelfItemsViewModelNew.movePageDelegate = shelfItemsViewModel.movePageDelegate
        shelfItemsViewModelNew.presentedViewController = shelfItemsViewModel.presentedViewController
        shelfItemsViewModelNew.selectedShelfItemToMove = nil
        return shelfItemsViewModelNew
    }
}
