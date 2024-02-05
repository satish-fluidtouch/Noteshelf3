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

class FTShelfTagsItem: NSObject {
    weak var documentItem: FTDocumentItemProtocol?
    var documentUUID: String?
    var pageUUID: String?
    var pageIndex: Int = 0
    var type: FTTagsType = .book;
}

final class FTShelfTagsPageModel: ObservableObject {
    var selectedTag: String = ""

    //TODO: Tag refactor
    func buildCache(completion: @escaping ([FTShelfTagsItem]) -> Void)  {
    }
}

 extension FTShelfTagsPageModel {
     //TODO: Tag refactor
      func processTags(reqItems: [FTShelfItemProtocol], selectedTags: [String], progress: Progress, completion: @escaping ([FTShelfTagsItem]) -> Void) {
     }

}
