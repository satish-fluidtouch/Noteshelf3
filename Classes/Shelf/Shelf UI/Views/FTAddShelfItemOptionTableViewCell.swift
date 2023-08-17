//
//  FTAddShelfItemOptionTableViewCell.swift
//  Noteshelf
//
//  Created by Siva on 20/06/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTAddShelfItemOptionTableViewCell: UITableViewCell {
    @IBOutlet weak var imageViewIcon: UIImageView!;
    @IBOutlet weak var nameLabel: FTSettingsLabel?;
    @IBOutlet weak var unreadBadgeLabel: FTStyledLabel!;
    @IBOutlet weak var accessoryImageView: UIImageView!

    fileprivate var currentOptionType = FTAddShelfItemOptionType.none;
    
    override func awakeFromNib() {
        self.unreadBadgeLabel.layer.cornerRadius = self.unreadBadgeLabel.frame.height * 0.5
        self.unreadBadgeLabel.layer.masksToBounds = true
    }
    
    func configure(withOptions option : FTAddShelfItemOption)
    {
        if(self.currentOptionType != option.type) {
            self.currentOptionType = option.type
            self.imageViewIcon.image = UIImage(named: option.imageName)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.1
            self.nameLabel?.attributedText = NSMutableAttributedString(string: option.name, attributes: [NSAttributedString.Key.kern: -0.32, NSAttributedString.Key.paragraphStyle: paragraphStyle])
        }
        self.unreadBadgeLabel.isHidden = true
    }
}
