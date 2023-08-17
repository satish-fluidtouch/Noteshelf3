//
//  FTBookmarkColorSectionHeader.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 07/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTBookmarkColorSectionHeader: UICollectionReusableView {
    
    @IBOutlet weak var textField: UITextField!
    override func awakeFromNib() {
        super.awakeFromNib()
        textField?.layer.borderWidth = 1
        textField?.layer.borderColor = UIColor.appColor(.black20).cgColor
        textField?.borderStyle = .none
        textField?.layer.cornerRadius = 10
    }
}
