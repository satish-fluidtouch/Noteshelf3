//
//  FTMoreTemplatesCollectionViewCell.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 03/03/23.
//

import UIKit

class FTMoreTemplatesCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak private var moreTemplateLabel: UILabel?
    @IBOutlet weak private var moreTemplatesButton: UIButton?

    func configureCell() {
        setBorder()
        moreTemplateLabel?.text = "newnotebook.moretemplates".localized
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
