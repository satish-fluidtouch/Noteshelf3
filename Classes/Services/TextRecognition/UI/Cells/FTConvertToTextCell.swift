//
//  FTConvertToTextCell.swift
//  Noteshelf
//
//  Created by Narayana on 18/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTConvertToTextCell: UITableViewCell {
    @IBOutlet weak var settingLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func extraConfigureCell() {
        self.accessoryType = .disclosureIndicator
        self.selectionStyle = .none
    }
}
