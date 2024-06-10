//
//  FTMoreTemplatesCollectionViewCell.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 03/03/23.
//

import UIKit
import FTCommon

class FTMoreTemplatesCollectionViewCell: FTTraitCollectionViewCell {
    @IBOutlet weak private var moreTemplateLabel: UILabel?
    @IBOutlet weak private var moreTemplatesButton: UIButton?
    @IBOutlet private weak var moreTemplateBtnWidthConstraint: NSLayoutConstraint?

    private var paperPickerMode: FTPaperPickerMode = .paperPicker
    
    func configureCell(mode: FTPaperPickerMode) {
        setBorder()
        moreTemplateLabel?.text = "newnotebook.moretemplates".localized
        self.paperPickerMode = mode
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateImgWidthConstraint()
    }

    func updateImgWidthConstraint() {
        if self.paperPickerMode == .paperPicker {
            self.moreTemplateBtnWidthConstraint?.constant = self.isRegular ? 120 : 100
        } else {
            self.moreTemplateBtnWidthConstraint?.constant = 120
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            setBorder()
        }
    }
    private func setBorder(){
        self.moreTemplatesButton?.layer.borderColor = UIColor.appColor(.moreTemplatesBorderTint).cgColor
        self.moreTemplatesButton?.layer.borderWidth = 1.0
    }
}
