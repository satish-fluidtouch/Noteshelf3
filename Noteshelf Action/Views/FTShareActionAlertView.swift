//
//  FTShareActionAlertView.swift
//  Noteshelf Action
//
//  Created by Sameer Hussain on 12/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTShareAlertDelegate: AnyObject {
    func doneButtonAction()
}

class FTShareActionAlertView: UIView {
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var unsupportedDoneButton: UIButton!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var alertTitle: UILabel!
    @IBOutlet weak var unSupportedTiitleLabel: UILabel!
    weak var del: FTShareAlertDelegate?
    @IBOutlet weak var animationImageView: UIImageView!
    @IBOutlet weak var unspportedFileView: UIView!
    @IBOutlet weak var alertStackView: UIStackView!
    var numberOfSharedItems = 0
    var animationState = FTAnimationState.none {
        didSet {
            self.updateAlert()
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.layer.cornerRadius = 14
        self.contentView.backgroundColor = .clear
        self.contentView.addVisualEffectBlur(cornerRadius: 14)
        self.updateAlert()
        self.doneButton.layer.cornerRadius = 10
        self.animationState = .none
        self.isHidden = true
        self.contentView.addShadow(color: .black.withAlphaComponent(0.2), offset: CGSize(width: 0, height: 10), opacity: 1, shadowRadius: 20)
    }
    
    @IBAction func onDoneTapped(_ sender: Any) {
        del?.doneButtonAction()
    }
    
    func showUnsupportedAlert() {
        self.isHidden = false
        unSupportedTiitleLabel.text = "NotSupportedFormat".localized
        unsupportedDoneButton.layer.cornerRadius = 10
        self.alertStackView.isHidden = true
        self.unspportedFileView.isHidden = false
    }

    func updateAlert() {
        switch (animationState) {
        case .none:
            self.alertStackView.isHidden = true
        case .started:
            self.isHidden = false
            self.alertStackView.isHidden = false
            self.doneButton.isHidden = true
            break
        case .ended:
            self.isHidden = false
            self.animationImageView.image = UIImage(named: "animation_end")
            self.alertTitle.text = "\(numberOfSharedItems) files sent to Noteshelf"
            self.doneButton.isHidden = false
            break
        }
    }
}
