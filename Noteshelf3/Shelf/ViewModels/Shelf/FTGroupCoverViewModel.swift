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
    private var observerAdded = false;
    var groupItem: FTGroupItem? {
        didSet {
            if groupItem != oldValue {
                if let _groupItem = oldValue {
                    self.removeObserver(_groupItem);
                }
                if nil != groupItem {
                    self.addGroupUpdatedObserver()
                }
            }
        }
    }
    
    @Published var groupNotebooks: [FTShelfItemViewModel] = []
    var groupCoverProperties:   FTShelfItemCoverViewProperties = .large
    private var cancellables = [AnyCancellable]()
    var isVisible: Bool = false
    private var groupNotebookItemsCache = [String: FTShelfItemViewModel]();


    init(groupItem: FTGroupItem? = nil) {
        self.groupItem = groupItem
    }

    func fetchTopNotebookOfGroup(_ group: FTGroupItemProtocol?) {
        if !isVisible {
            return
        }
        let currentOrder = FTUserDefaults.sortOrder()
        if (group as? FTGroupItem)?.shelfCollection != nil {
            (group as? FTGroupItem)?.fetchTopNotebooks(sortOrder: currentOrder,noOfBooksTofetch: 4, onCompletion: { [weak self ] top4Children in
                if !top4Children.isEmpty {
                    self?.createGroupItemsFromData(top4Children, completion: { groupChildItems in
                        self?.groupNotebooks = groupChildItems
                    })
                } else {
                    self?.groupNotebooks = []
                }
            })
        }
    }

    // MARK: For Cover Image
    private func createGroupItemsFromData(_ shelfItems: [FTShelfItemProtocol], completion: @escaping ([FTShelfItemViewModel]) -> Void) {
        let group = DispatchGroup()
        var groupChildItems: [FTShelfItemViewModel] = []

        for shelfItem in shelfItems {
            let item = self.createShelfItemFromData(shelfItem)
            groupChildItems.append(item)

            group.enter()

            var token: String?
            token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(shelfItem) { [weak self](image, imageToken) in
                guard let self = self else {
                    group.leave()
                    return
                }
                if token == imageToken, let image {
                    item.coverImage = image
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(groupChildItems)
        }
    }
    private func createShelfItemFromData(_ shelfItemData: FTShelfItemProtocol) -> FTShelfItemViewModel{
        let shelfItemToreturn: FTShelfItemViewModel
        if let item = self.shelfItemFor(shelfItemData) {
            shelfItemToreturn = item
        }
        else {
            shelfItemToreturn = FTShelfItemViewModel(model: shelfItemData);
        }
        self.groupNotebookItemsCache[shelfItemData.uuid] = shelfItemToreturn
        return shelfItemToreturn
    }
    private func shelfItemFor(_ item: FTShelfItemProtocol) -> FTShelfItemViewModel? {
        return groupNotebookItemsCache[item.uuid];
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
        if let _groupItem = self.groupItem {
            self.removeObserver(_groupItem)
        }
    }
    
    private func removeObserver(_ _groupItem: FTGroupItem) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "GroupUpdatedNotification"), object: _groupItem)
    }
}
