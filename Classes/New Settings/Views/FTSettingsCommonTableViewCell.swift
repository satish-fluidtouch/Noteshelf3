//
//  FTSettingsCommonTableViewCell.swift
//  Noteshelf
//
//  Created by Matra on 11/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSettingsCommonTableViewCell: FTSettingsBaseTableViewCell {
    @IBOutlet private weak var smallImageIcon: UIImageView?
    @IBOutlet private weak var nameLabel: FTSettingsLabel?
    @IBOutlet private weak var linkView: UIView?
    @IBOutlet private weak var linkLabel: FTSettingsLabel?

    @IBOutlet weak var accessoryIcon: UIImageView?

    var hideAccessoryIcon: Bool = false {
        didSet {
            accessoryIcon?.isHidden = hideAccessoryIcon
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.backgroundColor = UIColor.systemBackground
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.appColor(.black5)
        self.selectedBackgroundView = backgroundView
        linkLabel?.fontStyle = FTSettingFontStyle.smallDetail.rawValue
        self.linkView?.layer.cornerRadius = (linkView?.bounds.height)! / 2
        self.linkView?.isHidden = true
        self.linkView?.backgroundColor = UIColor(red: 74 / 255.0, green: 161 / 255, blue: 255 / 255, alpha: 1.0)
        self.linkLabel?.textColor = .white
    }

    func populateCell(image: UIImage?, name: String?, showLinkView: Bool ) {
        if let reqImage = image {
            self.smallImageIcon?.image = reqImage
        }
        if let reqName = name {
            self.nameLabel?.text = NSLocalizedString(reqName, comment: reqName)
            self.nameLabel?.addCharacterSpacing(kernValue: -0.41)
        }
        self.linkView?.isHidden = !showLinkView
    }

    func showNewPaperFlag() {
        self.linkView?.isHidden = false
        self.linkView?.backgroundColor = UIColor(red: 242 / 255.0, green: 186 / 255, blue: 36 / 255, alpha: 1.0)
        self.linkLabel?.text = "New".localized
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.linkView?.backgroundColor = UIColor(red: 74 / 255.0, green: 161 / 255, blue: 255 / 255, alpha: 1.0)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.linkView?.backgroundColor = UIColor(red: 74 / 255.0, green: 161 / 255, blue: 255 / 255, alpha: 1.0)
    }
}
