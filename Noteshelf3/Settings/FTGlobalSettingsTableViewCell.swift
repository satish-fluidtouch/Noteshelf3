//
//  FTGlobalSettingsTableViewCell.swift
//  Noteshelf3
//
//  Created by Rakesh on 10/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTGlobalSettingsTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var globalSettingsimageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

class FTGlobalSettingsSafeModeTableViewCell: UITableViewCell {

    @IBOutlet weak var settingsImageView: UIImageView!
    @IBOutlet weak var safeModeSwitch: UISwitch!
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        safeModeSwitch.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func updateSwitchState() {
        let isSafeModeEnabled = FTUserDefaults.isInSafeMode()
        safeModeSwitch.isOn = isSafeModeEnabled
    }

    @objc func switchValueChanged() {
        FTUserDefaults.setSafeMode(isOn: safeModeSwitch.isOn)
    }
}
