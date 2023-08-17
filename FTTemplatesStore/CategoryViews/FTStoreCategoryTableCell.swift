//
//  FTStoreCategoryTableCell.swift
//  FTTemplates
//
//  Created by Siva on 16/02/23.
//

import UIKit
import Combine
import FTCommon
import SwiftUI

class FTStoreCategoryTableCell: UITableViewCell {

    private var templatesStoreInfo: StoreInfo!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func prepareCellWith(templatesStoreInfo: StoreInfo) {
        self.templatesStoreInfo = templatesStoreInfo
        self.contentConfiguration = UIHostingConfiguration {
            FTStoreCategoryView(templateInfo: templatesStoreInfo)
        }
        .background {
            Color.clear
        }
    }
}
