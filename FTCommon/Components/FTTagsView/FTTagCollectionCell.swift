//
//  FTTagCollectionCell.swift
//  FTTagsView
//
//  Created by Siva on 15/11/22.
//

import UIKit

class FTTagCollectionCell: UICollectionViewCell {
    static let id = "FTTagCollectionCell"
    @IBOutlet private var iconView: UIImageView!
    @IBOutlet private var label: UILabel!

    private var configuration: FTTagViewConfiguration!

    override var isSelected: Bool {
        didSet {
            if isSelected {
                // Apply the tapping effect
                contentView.backgroundColor = UIColor.black
                self.label.textColor = .white
            } else {
                // Remove the tapping effect
                contentView.backgroundColor = configuration.tagBgColor
                self.label.textColor = configuration.textColor
            }
        }
    }


    func setCellModel(model: FTTagModel, configuration: FTTagViewConfiguration) {
        self.configuration = configuration
        label.text = model.text
        if let img = model.image {
            iconView.image = img
        } else {
            iconView.isHidden = true
        }
        label.font = configuration.textFont
        self.contentView.backgroundColor = model.isSelected ? configuration.tagSelectedBgColor : configuration.tagBgColor
        layer.borderColor = configuration.borderColor.cgColor
        label.textColor = model.isSelected ? configuration.selectedTextColor : configuration.textColor
        
    }

    override func awakeFromNib() {
        layer.cornerRadius = 8
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 1
        clipsToBounds = true
    }
}
