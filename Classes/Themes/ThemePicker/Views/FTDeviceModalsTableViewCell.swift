//
//  FTDeviceModalsTableViewCell.swift
//  FTTemplatePicker
//
//  Created by Ramakrishna on 07/08/20.
//  Copyright © 2020 Mahesh. All rights reserved.
//

import UIKit

class FTDeviceModalsTableViewCell: UITableViewCell {

    @IBOutlet weak var checkmarkAccessoryImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
