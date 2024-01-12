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
import Combine

class FTStoreCategoryTableCell: UITableViewCell {

    private var templatesStoreInfo: StoreInfo!
    private var actionStream: PassthroughSubject<FTStoreActions, Never>?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func prepareCellWith(templatesStoreInfo: StoreInfo, actionStream: PassthroughSubject<FTStoreActions, Never>?) {
        self.templatesStoreInfo = templatesStoreInfo
        self.actionStream = actionStream
        self.contentConfiguration = UIHostingConfiguration {
            FTStoreCategoryView(templateInfo: templatesStoreInfo, actionStream: actionStream)
        }
        .background {
            Color.clear
        }
    }
}
