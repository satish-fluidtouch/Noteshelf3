//
//  FTShelfItemAddNewTableViewCell.swift
//  Noteshelf
//
//  Created by Siva on 09/10/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTShelfItemAddNewTableViewCell: UITableViewCell {
    @IBOutlet weak var addNewLabel: UILabel!
    var cellPurpose: FTShelfAddNew = .notebook
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.layer.cornerRadius = 10.0
    }
    
}
