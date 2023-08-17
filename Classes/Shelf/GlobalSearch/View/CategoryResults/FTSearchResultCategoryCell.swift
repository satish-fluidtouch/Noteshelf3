//
//  FTSearchResultCategoryCellCollectionViewCell.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 24/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

class FTSearchResultCategoryCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var folderImageView: UIImageView?

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCellWithItem(_ searchItem: FTSearchResultCategoryProtocol,
                                 searchKey: String){
        self.titleLabel?.setTitle(title: searchItem.title, highlight: searchKey)
    }
}
