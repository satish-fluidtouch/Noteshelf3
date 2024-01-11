//
//  FTLinkTextTableViewCell.swift
//  Noteshelf3
//
//  Created by Narayana on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTLinkTextTableViewCell: UITableViewCell {
    static let linkTextCellId = "FTLinkTextTableViewCell"

    @IBOutlet private weak var linkTextLabel: UILabel!
    @IBOutlet private weak var linkTextTf: UITextField!

    func configureCell(with option: FTLinkToOption) {
        self.linkTextLabel.text = option.rawValue
    }
}
