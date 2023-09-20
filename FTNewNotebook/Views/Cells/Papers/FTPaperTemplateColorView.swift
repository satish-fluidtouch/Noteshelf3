//
//  FTPaperTemplateColorView.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 24/02/23.
//

import UIKit
import FTStyles
import FTCommon

protocol FTPaperTemplateCustomColorDelegate: NSObject {
    func didSelectCustomColor(_ color:UIColor?)
}

final class FTPaperTemplateColorButton: FTInteractionButton {
    var templateColor: FTTemplateColorModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    var isColorSelected: Bool = false {
        didSet {
            setBorder()
        }
    }

    func configureViewWith(templateColor: FTTemplateColorModel, isSelected:Bool = false) {
        self.templateColor = templateColor
        self.backgroundColor = UIColor(hexWithAlphaString: templateColor.hex)
        self.isColorSelected = isSelected
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            setBorder()
        }
    }
    private func setBorder(){
        if isColorSelected {
            self.layer.borderWidth = 2.5
            self.layer.borderColor = FTNewNotebook.Constants.SelectedAccent.tint.cgColor
        } else {
            self.layer.borderWidth = 1.0
            self.layer.borderColor = UIColor.appColor(.black20).cgColor
        }
    }
}

final class FTPaperTemplateColorWell: UIColorWell {
    weak var customColorDelegate: FTPaperTemplateCustomColorDelegate?

    override func awakeFromNib() {
        self.supportsAlpha = false
        self.addTarget(self, action: #selector(didSelectCustomColor), for: .valueChanged)
    }

    @objc private func didSelectCustomColor() {
        self.customColorDelegate?.didSelectCustomColor(self.selectedColor)
    }
}
