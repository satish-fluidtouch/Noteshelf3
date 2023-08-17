//
//  FTQuickCreateSettingsTableViewCell.swift
//  Noteshelf
//
//  Created by Siva on 31/05/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTQuickCreateSettingsRandomTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: FTSettingsLabel?
    @IBOutlet weak var randomCoverSwitch: UISwitch?

    override func awakeFromNib() {
        super.awakeFromNib();
        
        self.titleLabel?.text = NSLocalizedString("RandomCoverDesign", comment: "Random Cover");
        
    }
}

class FTQuickCreateSettingsTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: FTSettingsLabel?
    @IBOutlet weak var subTitleLabel: FTSettingsLabel?
    @IBOutlet weak var separatorView: UIView!;

    override func awakeFromNib() {
        super.awakeFromNib();
        
    }
}
