//
//  FTStylusCollectionViewCell.swift
//  Noteshelf
//
//  Created by Siva on 14/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension UICollectionViewCell {
    static func reusableIdentifier() -> String {
        return String(describing: self);
    }
}

extension UITableViewCell {
    static func reusableIdentifier() -> String {
        return String(describing: self);
    }
}

class FTStylusCollectionViewCell: UICollectionViewCell {

    override func awakeFromNib() {
        super.awakeFromNib();
    }
}
