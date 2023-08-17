//
//  FTNewNotebookSettingTableViewCell.swift
//  Noteshelf
//
//  Created by Siva on 28/04/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTNewNotebookSettingTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: FTSettingsLabel?
    @IBOutlet weak var switchToToggle: UISwitch?
    @IBOutlet weak var actionButton: UIButton?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.backgroundColor = .systemBackground
        self.switchToToggle?.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        self.switchToToggle?.layer.borderWidth = 1.0
        if switchToToggle != nil {
            self.switchToToggle?.layer.cornerRadius = self.switchToToggle!.frame.size.height/2.0
        }
    }

    func enable(_ status: Bool) {
        self.titleLabel?.isEnabled = status
        self.switchToToggle?.isEnabled = status
        self.actionButton?.isEnabled = status
    }
}
