//
//  FTGroupItem.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 15/06/22.
//

import Foundation
import SwiftUI

class FTGroupItemViewModel: FTShelfItemViewModel {
    
    override var type: FTShelfItemType {
        return .group;
    }
    
    @Published var groupCoverViewModel: FTGroupCoverViewModel = FTGroupCoverViewModel()

    var noOfNotes: String {
        if let noOfNotes = (self.shelfItem as? FTGroupItemProtocol)?.childrens.count {
            if noOfNotes == 1 {
                return "\(noOfNotes) " + "groupitem.noteText".localized
            } else {
                return "\(noOfNotes) " + "groupitem.notesText".localized
            }
        }
        return ""
    }
    
    override var longPressOptions: [[FTShelfItemContexualOption]] {
        FTShelfItemContextualMenuOptions(id: id, shelfItem: self, shelfItemCollection: model.shelfCollection).longPressActions
    }
    
    override init(model: FTShelfItemProtocol) {
        super.init(model: model)
        self.shelfItem = model
    }
    deinit {
        self.removeAllKeyPathObservers()
        self.removeUrlObserversIfNeeded()
    }
    
    override func notebookShape() -> AnyShape {
        return AnyShape(RoundedRectangle(cornerRadius: 10));
    }
}
