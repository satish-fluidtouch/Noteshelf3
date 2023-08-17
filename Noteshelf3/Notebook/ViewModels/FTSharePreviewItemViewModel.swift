//
//  FTSharePreviewItemViewModel.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 29/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI

class FTSharePreviewItemViewModel: NSObject, ObservableObject, Identifiable {
    @Published var coverImage: UIImage? = UIImage(named: "defaultNoCover")
    func fetchThumbnailsForShelfItem(_ shelfItem:FTShelfItemProtocol) {
        fatalError("Chlid class need to override this method.")
    }
    func fetchPageThumbnail(){
        fatalError("Chlid class need to override this method.")
    }
}
class FTShareNotebookPreviewViewModel: FTSharePreviewItemViewModel {
    var shelfItem: FTShelfItemProtocol

    init(shelfItem: FTShelfItemProtocol) {
        self.shelfItem = shelfItem
    }

    override func fetchThumbnailsForShelfItem(_ shelfItem:FTShelfItemProtocol){
        var token : String?
        token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(shelfItem, onCompletion: { [weak self](image, imageToken) in
            guard let weakSelf = self else {
                return
            }
            if token == imageToken {
                if let image {
                    weakSelf.coverImage = image
                }
            }
        })
    }
}
class FTShareGroupItemPreviewViewModel: FTSharePreviewItemViewModel {
    var group: FTGroupItemProtocol
    var groupCoverViewModel: FTGroupCoverViewModel = FTGroupCoverViewModel()

    init(group:FTGroupItemProtocol){
        self.group = group
    }
}
class FTSharePageItemPreviewViewModel: FTSharePreviewItemViewModel {
    var page:FTPageProtocol

    init(page:FTPageProtocol){
        self.page = page
    }
    override func fetchPageThumbnail(){
        self.page.thumbnail()?.thumbnailImage(onUpdate: {[weak self] (image, error) in
            guard let weakSelf = self else {
                return
            }
            if let image {
                weakSelf.coverImage = image
            }
        })
    }
}
