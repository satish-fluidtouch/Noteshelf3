//
//  FTRootViewController.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 20/04/22.
//

import UIKit
import SwiftUI
import Combine

class FTShelfViewControllerNew: FTShelfBaseHostingController {
    //private var viewModel: FTShelfViewModel!
    var shelfItemCollection: FTShelfItemCollection?
    var parentShelfItem: FTGroupItemProtocol?
    private var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo;

    required init(shelfViewModel model: FTShelfViewModel, shelfMenuOverlayInfo info: FTShelfMenuOverlayInfo) {
        shelfMenuOverlayInfo = info;
        super.init(rootView: AnyView(FTShelfView().environmentObject(model).environmentObject(info)));
        self.shelfViewModel = model;
        model.groupViewOpenDelegate = self;
    }

    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
    }
}

extension FTShelfViewControllerNew: FTShelfViewDelegate {
    func didTapOnShelfItem(_ item: FTShelfItemProtocol) {
        let shelfItemProtocol: FTShelfItemProtocol = item
        if let groupItemProtocol = shelfItemProtocol as? FTGroupItemProtocol, let collection = groupItemProtocol.shelfCollection {
            let newShelfViewModel = FTShelfViewModel(collection: collection , groupItem: groupItemProtocol)
            newShelfViewModel.delegate = self.shelfViewModel.delegate
            newShelfViewModel.tagsControllerDelegate = self.shelfViewModel.tagsControllerDelegate
            newShelfViewModel.compactDelegate = self
            newShelfViewModel.isSidebarOpen = self.splitViewController?.displayMode == .oneBesideSecondary
            let newShelfViewController = FTShelfViewControllerNew(shelfViewModel: newShelfViewModel,shelfMenuOverlayInfo: shelfMenuOverlayInfo)
            newShelfViewController.shelfItemCollection = groupItemProtocol.shelfCollection
            newShelfViewController.parentShelfItem = groupItemProtocol
            newShelfViewController.title = groupItemProtocol.displayTitle
            self.navigationController?.pushViewController(newShelfViewController, animated: true)
        } else {
            
        }
    }
}
extension FTShelfViewControllerNew: FTShelfCompactViewModelProtocol {
    func didChangeSelectMode(_ mode: FTShelfMode) {
        if mode == .selection {
            self.navigationController?.tabBarController?.tabBar.isHidden = true
            self.navigationController?.tabBarController?.tabBar.layoutSubviews()
        } else {
            self.navigationController?.tabBarController?.tabBar.isHidden = false
        }
    }
}

extension FTShelfViewControllerNew: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
        self.shelfViewModel.endDragAndDropOperation();
        debugPrint("dropInteraction sessionDidEnd")
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        debugPrint("dropInteraction sessionDidExit")
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, concludeDrop session: UIDropSession) {
        debugPrint("dropInteraction concludeDrop")
    }
}
