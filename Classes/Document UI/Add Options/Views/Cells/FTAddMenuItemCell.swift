//
//  FTAddMenuItemCell.swift
//  FTAddOperations
//
//  Created by Siva on 04/06/20.
//  Copyright © 2020 Siva. All rights reserved.
//

import Foundation
import UIKit

class FTAddMenuItemCell: UITableViewCell {

    
    @IBOutlet weak var thumbImage: UIImageView?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var disclosureImage: UIImageView?
    @IBOutlet weak var topsSeperatorView: UIView?
    
    
    var addOnOptionSelected: ((FTAddMenuItemProtocol) -> Void)?
    
    private var menuItem: FTAddMenuItemProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let view = UIView()
        view.backgroundColor = UIColor.appColor(.black5)
        selectedBackgroundView = view
    }
    
    func configure(with item:FTAddMenuItemProtocol, indexPath: IndexPath) {
        
        menuItem = item
        switch item.type {
        case .basic:
            disclosureImage?.isHidden = true
        case .disclose:
            disclosureImage?.isHidden = false
        }
        titleLabel?.textColor = .label
        titleLabel?.text = item.localizedTitle.localized
        titleLabel?.addCharacterSpacing(kernValue: -0.32)
        thumbImage?.image = UIImage(named: item.thumbImage)
        self.backgroundColor = UIColor.appColor(.cellBackgroundColor)
    }
}
