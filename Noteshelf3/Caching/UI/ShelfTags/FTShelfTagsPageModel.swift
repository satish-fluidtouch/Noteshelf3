//
//  FTShelfTagsPageModel.swift
//  Noteshelf3
//
//  Created by Siva on 08/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Combine
import Foundation
import UIKit
import FTCommon

enum FTShelfTagsPageLoadState {
    case loading
    case loaded
    case empty
}

enum FTShelfTagsItemType {
    case page, book, none
}

 class FTShelfTagsItem: NSObject,Identifiable {

    var id: UUID = UUID()
    weak var documentItem: FTDocumentItemProtocol?
    var documentUUID: String?
    var pageUUID: String?
    var pageIndex: Int = 0
    var pdfKitPageRect: CGRect?
    var type: FTShelfTagsItemType = .none
    var tags: [FTTagModel] = [FTTagModel]() {
        didSet {
            self.tags = Array(Set(tags))
        }
    }

     func setTags(_ tagNames: [String]) {
        tagNames.forEach { eachTag in
            if let tagItem = FTTagsProvider.shared.getTagItemFor(tagName: eachTag) {
                self.tags.append(tagItem.tag)
            } else {
                self.tags.append(FTTagModel(text: eachTag))
            }
        }
    }

     func removeAllTags() {
            self.tags.removeAll()
    }

    private var observerProtocol: AnyObject?;

     init(documentItem: FTDocumentItemProtocol, documentUUID: String?, type: FTShelfTagsItemType) {
        super.init()
        self.documentItem = documentItem
        self.documentUUID = documentUUID
        self.type = type
    }
     
     override func isEqual(_ object: Any?) -> Bool {
         guard let other = object as? FTShelfTagsItem
                ,other.type == self.type else {
             return false;
         }
         if self.type == .book {
             return self.documentUUID == other.documentUUID;
         }
         else if self.type == .page {
             return self.documentUUID == other.documentUUID && self.pageUUID == other.pageUUID
         }
         return false;
     }
}

final class FTShelfTagsPageModel: ObservableObject {
    var selectedTag: String = ""

    func buildCache(completion: @escaping ([FTShelfTagsItem]) -> Void)  {
        if let selectedTagItem = FTTagsProvider.shared.getTagItemFor(tagName: selectedTag) {
            selectedTagItem.getTaggedItems(completion: { [weak self] tagsPage in
                var tagItems = tagsPage
                tagItems.removeAll(where: {$0.tags.isEmpty})
                if self?.selectedTag.count ?? 0 > 0 {
                    tagItems = tagItems.filter { item in
                        // Check if the item's tags do not contain the selectedTag's text
                        return item.tags.map { $0.text }.contains(self?.selectedTag)
                    }
                }
                completion(tagItems)
            })
        } else {
            completion([])
        }

    }
}

 extension FTShelfTagsPageModel {
      func processTags(reqItems: [FTShelfItemProtocol], selectedTags: [String], progress: Progress, completion: @escaping ([FTShelfTagsItem]) -> Void) {
         var totalTagItems: [FTShelfTagsItem] = [FTShelfTagsItem]()
         let dispatchGroup = DispatchGroup()
         selectedTags.forEach { eachTag in
             dispatchGroup.enter()

             let tagItem = FTTagsProvider.shared.getTagItemFor(tagName: eachTag)
              tagItem?.getTaggedItems(completion: { items in
                 totalTagItems.append(contentsOf: items)
                  progress.completedUnitCount += 1
                 dispatchGroup.leave()
             })
         }
         dispatchGroup.notify(queue: .main) {
             var commonShelfss = [FTShelfTagsItem]()
             totalTagItems.forEach { each in
                 let tags = each.tags.map({$0.text}).sorted()
                 let isCommonTags = selectedTags.allSatisfy(tags.contains(_:))
                 if isCommonTags {
                     commonShelfss.append(each)
                 }
             }
             completion(Array(Set(commonShelfss)))
         }
     }

}
