//
//  FTShelfFooterView.swift
//  Noteshelf
//
//  Created by Narayana on 02/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//
/*
import UIKit

class FTShelfFooterView: UICollectionReusableView {

    @IBOutlet weak var countInfoLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func updateCountInfo(shelfItems: [FTShelfItemProtocol]) {
        var shelfItemsRequired = shelfItems
        shelfItemsRequired.removeAll { item in
            item is FTQuickCreateShelfItem
        }
        let postCountText = shelfItemsRequired.count == 1 ? "Item" : "Items"
        self.countInfoLabel.text = "\(shelfItemsRequired.count) \(postCountText)"
        self.countInfoLabel.addCharacterSpacing(kernValue: -0.4)
    }
    
}
*/
