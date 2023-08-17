//
//  FTColorCell.swift
//  Noteshelf
//
//  Created by Mahesh on 01/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTColorWellDelegate: NSObjectProtocol {
    func didSelectColor(_ color: UIColor?)
}

class FTColorCell: UICollectionViewCell {

    @IBOutlet private weak var cellSelectedImg: UIImageView?
    @IBOutlet weak var colorWellBtn: UIColorWell?
    weak var delegate: FTColorWellDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
        self.colorWellBtn?.layer.borderColor = UIColor.appColor(.gray60).cgColor
        self.colorWellBtn?.layer.borderWidth = 1.0
        self.colorWellBtn?.layer.cornerRadius = self.colorWellBtn!.frame.height/2
    }
    
    override var isSelected: Bool {
        didSet {
            self.cellSelectedImg?.isHidden = !isSelected
        }
    }
    
    func updatebackgroundColor(colorStr: String) {
        self.colorWellBtn?.isHidden = true
        self.cellSelectedImg?.isHidden = true
        self.contentView.backgroundColor = UIColor(hexString: colorStr)
        self.contentView.layer.cornerRadius = 18
        self.contentView.layer.borderColor = UIColor.appColor(.gray60).cgColor
        self.contentView.layer.borderWidth = 1.0
        self.colorWellBtn?.selectedColor = nil
    }

    func updateCustomColorCellUI(_ color: String?) {
        self.cellSelectedImg?.isHidden = true
        self.colorWellBtn?.isHidden = false
        if let clr = color {
            self.colorWellBtn?.selectedColor = UIColor(hexString: clr)
        } else {
            self.colorWellBtn?.selectedColor = nil
        }
        self.contentView.backgroundColor = UIColor.clear
    }
    
    @IBAction func tappedOnColorWell(_ sender: UIColorWell) {
        self.delegate?.didSelectColor(sender.selectedColor)
    }
}
