//
//  FTErrorInfoTableViewCell.swift
//  Noteshelf3
//
//  Created by Narayana on 05/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTErrorInfoTableViewCell: UITableViewCell {
    @IBOutlet private weak var errorImgIndicator: UIImageView?
    @IBOutlet private weak var bookTitleLabel: UILabel?
    @IBOutlet private weak var bookLocationLabel: UILabel?
    @IBOutlet private weak var errorLabel: UILabel?

    func configureErrorInfo(with item: FTBackupIgnoreEntry) {
        self.bookTitleLabel?.text = item.title
        self.errorLabel?.text = item.ignoreReason
    }
}
