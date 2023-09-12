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
    static let warning_View_Height: CGFloat = 23;
    
    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var seperator: UIView!
    @IBOutlet private weak var labelError: UILabel!

    @IBOutlet private weak var errorLabelHeightConstraint: NSLayoutConstraint?
    
    @IBOutlet private weak var pdfContentWarnLableHeight: NSLayoutConstraint?
    @IBOutlet private weak var pdfContentWarnLable: UILabel?

    @IBOutlet weak var infoLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var errorInfoBtn: UIButton!

    var errorInfoTapHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.infoView.layer.cornerRadius = 8.0
        self.errorInfoBtn.setTitle("moreInfo".localized, for: .normal)
        self.errorInfoBtn.setTitleColor(UIColor.appColor(.accent), for: .normal)
        self.updateErrorMessage("")
        self.pdfContentWarnLable?.text = "cloud.backup.pdfFormatWarning".localized
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
    
    func setBackupFormat(_ format: FTCloudBackupFormat) {
        if format != .noteshelf {
            self.pdfContentWarnLableHeight?.constant = FTBackupFooterView.warning_View_Height;
            self.layoutIfNeeded();
        }
        else {
            self.pdfContentWarnLableHeight?.constant = 0;
            self.layoutIfNeeded();
        }
    }
}
