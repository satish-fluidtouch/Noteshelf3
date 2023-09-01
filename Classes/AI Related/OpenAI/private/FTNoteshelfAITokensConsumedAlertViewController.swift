//
//  FTNoteshelfAITokensConsumedAlertViewController.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 04/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTNoteshelfButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            if cornerRadius != oldValue {
                commoninit();
            }
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        commoninit();
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        commoninit();
    }
    
    override func awakeFromNib() {
        super.awakeFromNib();
        commoninit();
    }
    
    private func commoninit() {
        self.layer.cornerRadius = self.cornerRadius;
    }
}

class FTNoteshelfAITokensConsumedAlertViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel?
    
    @IBOutlet weak var messageLabel: UILabel?

    @IBOutlet weak var sendFeedback: FTNoteshelfButton?
    
    private var titleFont: UIFont {
        return UIFont.clearFaceFont(for: .medium, with: 28);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layer.cornerRadius = 10;
        self.titleLabel?.attributedText = "noteshelf.ai.tokenCompleteTitle".aiLocalizedString.appendBetalogo(font: self.titleFont);
        self.messageLabel?.text = "noteshelf.ai.tokenCompleteMessage".aiLocalizedString;

        let font = self.sendFeedback?.titleLabel?.font ?? UIFont.systemFont(ofSize: 13, weight: .bold);
        let attributedTitle = NSAttributedString(string: "noteshelf.ai.sendFeedback".aiLocalizedString, attributes: [.font:font]);
        self.sendFeedback?.setAttributedTitle(attributedTitle, for: .normal)
    }
    
    @IBAction func sendFeedbackTapped(_ sender: UIButton) {
        FTZenDeskManager.shared.showSupportContactUsScreen(controller: self.parent ?? self
                                                           , defaultSubject: "Noteshelf-AI Feedback"
                                                           , extraTags: ["Noteshelf-AI"]);
    }
}
