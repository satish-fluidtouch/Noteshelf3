//
//  FTSaveClipCategoriesCell.swift
//  Noteshelf3
//
//  Created by Siva on 22/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSaveClipCategoriesCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
           super.setSelected(selected, animated: animated)

           // Toggle the checkmark based on the cell selection
           accessoryType = selected ? .checkmark : .none
       }

}
