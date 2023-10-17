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
    var coverImage: UIImage? = UIImage(named: "shelfDefaultNoCover")
    @Published var groupNotebooks: [FTShelfItemViewModel] = []
    var groupCoverProperties:   FTShelfItemCoverViewProperties = .large
    private var cancellables = [AnyCancellable]()
    @Published var refreshGroup: Bool = false


    init(groupItem: FTGroupItem? = nil) {
        self.groupItem = groupItem
    }

    func fetchTopThreeGroupMembersOfGroup(_ group: FTGroupItemProtocol?, completionhandler: @escaping ([FTGroupCoverInfo]) -> ()) {
        var currentOrder = FTUserDefaults.sortOrder()
        //        if let userActivity = self.window?.windowScene?.userActivity {
        //            currentOrder = userActivity.sortOrder
        //        }
        if (group as? FTGroupItem)?.shelfCollection != nil {
            (group as? FTGroupItem)?.fetchTopNotebooks(sortOrder: currentOrder,noOfBooksTofetch: 4, onCompletion: { [weak self ] top4Children in
                if let shelfItems = self?.createShelfItemsFromData(top4Children) {
                    self?.groupNotebooks = shelfItems
                }
            })
        }
    }
    // MARK: For Cover Image
    func fetchCoverImageForShelfItem(_ item: FTShelfItemProtocol, completionhandler: @escaping (UIImage?) -> ()){
        var token : String?
        token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(item, onCompletion: { [weak self](image, imageToken) in
            if token == imageToken {
                completionhandler(self?.coverImage)
            }
        })
    }
    func createShelfItemsFromData(_ shelfItemsData: [FTShelfItemProtocol]) -> [FTShelfItemViewModel]{
        let items: [FTShelfItemViewModel] = shelfItemsData.map { item -> FTShelfItemViewModel in
            return FTShelfItemViewModel(model: item)
        }
        return items
    }
    @objc private func refreshGroupCover() {
        self.fetchTopThreeGroupMembersOfGroup(self.groupItem) { groupCoverInfo in
            print("fetched covers on cloud update")
        }
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
