//
//  FTConvertPreferencesCell.swift
//  Noteshelf
//
//  Created by Naidu on 20/07/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTConvertPreferencesCell: UITableViewCell {
    @IBOutlet var titleLabel: FTSettingsLabel?
    @IBOutlet var downloadButton: UIButton?
    @IBOutlet var activityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var labelSubTitle: FTSettingsLabel?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
