//
//  FTLanguageSelectionTableViewCell.swift
//  Noteshelf
//
//  Created by Matra on 17/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTLanguageSelectionTableViewCell: FTSettingsBaseTableViewCell {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var downloadButton: FTStyledButton?
    @IBOutlet weak var subTitleHeightConstraint: NSLayoutConstraint?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func populateCellWith(_ language: FTRecognitionLangResource) {
        if language.resourceStatus == .downloaded {
            self.downloadButton?.isHidden = true
            self.activityIndicator?.isHidden = true
            self.activityIndicator?.stopAnimating()
        } else if language.resourceStatus == .downloading {
            self.downloadButton?.isHidden = true
            self.activityIndicator?.isHidden = false
            self.activityIndicator?.startAnimating()
        }

        if language.languageCode == FTLanguageResourceManager.shared.currentLanguageCode && language.resourceStatus == .downloaded {
            self.downloadButton?.isHidden = false
            self.downloadButton?.setImage(UIImage(named: "checkBlack"), for: UIControl.State.normal)
        } else {
            self.downloadButton?.setImage(UIImage(named: "iclouddownload"), for: UIControl.State.normal)
        }

        self.labelTitle?.text = language.nativeDisplayName
        self.labelTitle?.addCharacterSpacing(kernValue: -0.41)
        if language.languageCode == languageCodeNone {
            self.labelSubTitle?.isHidden = true;
        }
        self.labelSubTitle?.text = language.displayName
        self.labelSubTitle?.addCharacterSpacing(kernValue: -0.41)
        self.subTitleHeightConstraint?.constant = (language.displayName == language.nativeDisplayName) ? 0 : 16
    }

    func prepareCell() {
        self.activityIndicator?.isHidden = true
        self.accessoryType = UITableViewCell.AccessoryType.none
        self.downloadButton?.isHidden = false
        self.activityIndicator?.stopAnimating()
        self.labelSubTitle?.isHidden = false;
    }
}
