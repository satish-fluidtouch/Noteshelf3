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

    func configureCell() {
        setBorder()
        moreTemplateLabel?.text = "newnotebook.moretemplates".localized
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateImgWidthConstraint()
    }

    func updateImgWidthConstraint() {
        self.moreTemplateBtnWidthConstraint?.constant = self.isRegular ? 120 : 100
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
