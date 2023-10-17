//
//  FTShelfItemModel.swift
//  Noteshelf3
//
//  Created by Akshay on 20/05/22.
//

import Foundation

enum ShelfItemType {
    case collection
    case group
    case notebook
}
class FTShelfItems: ObservableObject,Identifiable {

    var id: String
    var title: String
    var subTitle: String?
    var shelfItemType: ShelfItemType = .collection
    var collection: FTShelfItemCollection?
    var group: FTGroupItemProtocol?
    var notebook: FTShelfItemProtocol?
    @Published var coverImage: UIImage? = UIImage(named: "covergray")

    init(collection: FTShelfItemCollection) {
        self.id = collection.uuid
        self.title = collection.displayTitle
        self.shelfItemType = .collection
        self.collection = collection
    }
    var isNotDownloaded: Bool {
        notebook?.URL.downloadStatus() == .notDownloaded
    }
}

class FTShelfGroupItem: FTShelfItems {

    var groupCoverViewModel: FTGroupCoverViewModel = FTGroupCoverViewModel()

    init(group: FTGroupItemProtocol) {
        super.init(collection: group.shelfCollection)
        self.id = group.uuid
        self.title = group.displayTitle
        self.shelfItemType = .group
        self.group = group
        self.subTitle = "\(group.childrens.count)" + (group.childrens.count > 1 ? " items" : " item")
    }
}
class FTShelfNotebookItem: FTShelfItems {
    init(notebook: FTShelfItemProtocol) {
        super.init(collection: notebook.shelfCollection)
            self.id = notebook.uuid
            self.title = notebook.displayTitle
            self.shelfItemType = .notebook
            self.notebook = notebook
            self.collection = notebook.shelfCollection
            self.group = notebook.parent
            self.subTitle = notebook.fileModificationDate.shelfShortStyleFormat()
    }

    func fetchCoverImage(completionhandler: @escaping (UIImage?) -> ()){
        var token : String?
        if let shelfItemProtocol = notebook {
            token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(shelfItemProtocol, onCompletion: { [weak self](image, imageToken) in
                if token == imageToken {
                    self?.coverImage = (nil == image ? UIImage(named: "shelfDefaultNoCover") : image)
                    completionhandler(self?.coverImage)
                }
            })
        }
    }
}
