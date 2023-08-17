//
//  FTOutLineCell.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 12/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTOutlineCollectionViewCell: UICollectionViewCell {
    var outlinesView: UIView?
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureWith(outlinesView: UIView) {
        if self.outlinesView == nil {
            outlinesView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(outlinesView)
            outlinesView.addFullConstraints(self.contentView)
            self.outlinesView = outlinesView
        }
    }
}
