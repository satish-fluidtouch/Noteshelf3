//
//  FTTemplateMoreOptionsTableViewCell.swift
//  FTTemplatePicker
//
//  Created by Ramakrishna on 21/07/20.
//  Copyright © 2020 Mahesh. All rights reserved.
//

import UIKit

class FTTemplateMoreOptionsTableViewCell: UITableViewCell {

    @IBOutlet weak var checkmarkAccessoryImageView: UIImageView!
    @IBOutlet weak var chevronAccessoryImageView: UIImageView!
    @IBOutlet weak var lineSeperatorView: UIView!
    @IBOutlet weak var colorsView: UIView!
    @IBOutlet weak var lineHeightImageView: UIImageView!
    @IBOutlet weak var lineHeightTitle: UILabel!
    @IBOutlet weak var lineHeightDesc: UILabel!
    @IBOutlet weak var moreColorsTitle: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
