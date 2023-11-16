//
//  FTENUserInfoTableViewCell1.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 14/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTENUserInfoTableViewCell: UITableViewCell {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var labelInfo: UILabel?
    @IBOutlet weak var progressView: UIProgressView?
    @IBOutlet weak var infoLabelHeightConstraint: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.applySelectionStyleGray()
        // Initialization code
    }

    func updateInfoLabel(attrText: NSAttributedString) {
        guard let labelInfo = self.labelInfo else {
            return
        }
        let maxWidth: CGFloat = labelInfo.bounds.size.width
        let rect = attrText.boundingRect(with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                                         options: .usesLineFragmentOrigin,
                                         context: nil)
        let totalHeight = ceil(rect.size.height)
        self.labelInfo?.attributedText = attrText
        self.infoLabelHeightConstraint?.constant = totalHeight
        self.layoutIfNeeded();
    }
    func updateSubviewsVisibility(){
        if labelInfo?.text?.isEmpty ?? true {
            activityIndicator?.isHidden = false
            activityIndicator?.startAnimating()
            labelInfo?.isHidden = true
        } else {
            activityIndicator?.stopAnimating()
            activityIndicator?.isHidden = true
            labelInfo?.isHidden = false
        }
    }
    private func applySelectionStyleGray() {
        let backgroundView = UIView();
        backgroundView.backgroundColor = UIColor.appColor(.black5)
        self.selectedBackgroundView = backgroundView;
    }
}
