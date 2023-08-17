//
//  FTBackupFooterView.swift
//  Noteshelf
//
//  Created by Narayana on 30/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

class FTBackupFooterView: UITableViewHeaderFooterView {
    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var seperator: UIView!
    @IBOutlet private weak var labelError: UILabel!

    @IBOutlet private weak var errorLabelHeightConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var infoLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var errorInfoBtn: UIButton!

    var errorInfoTapHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.infoView.layer.cornerRadius = 8.0
        self.errorInfoBtn.setTitle("moreInfo".localized, for: .normal)
        self.errorInfoBtn.setTitleColor(UIColor.appColor(.accent), for: .normal)
        self.updateErrorMessage("")
    }

    func updateErrorMessage(_ msg: String) {
        if !msg.isEmpty {
            self.seperator.isHidden = false
            self.labelError.isHidden = false
            self.labelError.text = msg
            let height = msg.sizeWithFont(UIFont.appFont(for: .regular, with: 15)).height
            self.errorLabelHeightConstraint?.constant = height
        } else {
            self.seperator.isHidden = true
            self.labelError.isHidden = true
            self.errorLabelHeightConstraint?.constant = 0.0
        }
    }

    func updateInfoLabel(attrText: NSAttributedString) {
        let height = attrText.size().height
        self.infoLabelHeightConstraint?.constant = height
        self.labelInfo.attributedText = attrText
    }

    @IBAction func errorInfoTapped(_ sender: Any) {
            self.errorInfoTapHandler?()
    }
}
