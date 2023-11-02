//
//  FTGroupCoverViewModel.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 22/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import Combine

class FTGroupCoverViewModel: ObservableObject {

    var groupItem: FTGroupItem? {
        didSet {
            if groupItem != nil {
                self.addGroupUpdatedObserver()
            }
        }
    }
    
    @Published var groupNotebooks: [FTShelfItemViewModel] = []
    var groupCoverProperties:   FTShelfItemCoverViewProperties = .large
    private var cancellables = [AnyCancellable]()
    @Published var loadGroupItems: Bool = false
    var isVisible: Bool = false


    init(groupItem: FTGroupItem? = nil) {
        self.groupItem = groupItem
    }

    func fetchTopNotebookOfGroup(_ group: FTGroupItemProtocol?) {
        if !isVisible {
            return
        }
        var currentOrder = FTUserDefaults.sortOrder()
        //        if let userActivity = self.window?.windowScene?.userActivity {
        //            currentOrder = userActivity.sortOrder
        //        }
        loadGroupItems = false
        if (group as? FTGroupItem)?.shelfCollection != nil {
            (group as? FTGroupItem)?.fetchTopNotebooks(sortOrder: currentOrder,noOfBooksTofetch: 4, onCompletion: { [weak self ] top4Children in
                if !top4Children.isEmpty {
                    self?.createGroupItemsFromData(top4Children, completion: { groupChildItems in
                        self?.groupNotebooks = groupChildItems
                        self?.loadGroupItems = true
                    })
                } else {
                    self?.loadGroupItems = true
                }
            })
        }
    }

    // MARK: For Cover Image
    private func createGroupItemsFromData(_ shelfItems: [FTShelfItemProtocol], completion: @escaping ([FTShelfItemViewModel]) -> Void) {
        let group = DispatchGroup()
        var groupChildItems: [FTShelfItemViewModel] = []

        for shelfItem in shelfItems {
            group.enter()

            var token: String?
            token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(shelfItem) {(image, imageToken) in
                let item = FTShelfItemViewModel(model: shelfItem)
                if token == imageToken, let image {
                    item.coverImage = image
                }
                groupChildItems.append(item)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(groupChildItems)
        }
    }
    @objc private func refreshGroupCover() {
        self.fetchTopNotebookOfGroup(groupItem)
    }
    private func addGroupUpdatedObserver(){
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refreshGroupCover),
                                               name: NSNotification.Name.init(rawValue: "GroupUpdatedNotification"),
                                               object: self.groupItem);
    }
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "GroupUpdatedNotification"), object: self.groupItem)
    }
}
