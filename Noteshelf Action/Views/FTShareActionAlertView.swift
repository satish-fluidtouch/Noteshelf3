//
//  FTShareActionAlertView.swift
//  Noteshelf Action
//
//  Created by Sameer Hussain on 12/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTShareActionAlertView: UIView {
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var alertTitle: UILabel!
    @IBOutlet weak var animationImageView: UIImageView!
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
