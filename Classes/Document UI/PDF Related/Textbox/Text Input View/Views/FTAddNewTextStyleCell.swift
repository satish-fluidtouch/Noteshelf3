//
//  FTAddNewTextStyleCell.swift
//  Noteshelf
//
//  Created by Mahesh on 31/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTAddNewTextStyleCell: UITableViewCell {

    @IBOutlet  weak var addNewpresetLbl: FTCustomLabel?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        addNewpresetLbl?.text = "shelf.notebook.textstyle.newpreset".localized
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
