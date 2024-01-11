//
//  FTLinkBookTableViewCell.swift
//  Noteshelf3
//
//  Created by Narayana on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTLinkBookTableViewCell: UITableViewCell {
    static let linkBookCellId = "FTLinkBookTableViewCell"

    @IBOutlet private weak var bookLabel: UILabel!
    @IBOutlet private weak var bookTitleLabel: UILabel!

    func configureCell(with option: FTLinkToOption, title: String) {
        self.bookLabel.text = option.rawValue
        self.bookTitleLabel.text = title
    }
}

