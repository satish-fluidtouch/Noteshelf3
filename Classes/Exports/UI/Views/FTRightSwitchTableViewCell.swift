//
//  FTRightSwitchTableViewCell.swift
//  Noteshelf
//
//  Created by Siva on 6/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTRightSwitchTableViewCell: FTExportBaseTableViewCell {
    
    @IBOutlet weak var labelTopLine: FTStyledLabel!
    @IBOutlet weak var labelTitle: FTStyledLabel!
    @IBOutlet weak var switchToToggle: UISwitch!
    @IBOutlet weak var labelBottomLine: FTStyledLabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.switchToToggle.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        self.switchToToggle.layer.borderWidth = 1.0
        self.switchToToggle.layer.cornerRadius = self.switchToToggle.frame.size.height/2.0
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
