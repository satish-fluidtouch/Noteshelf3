//
//  FTNoteshelfAITokensConsumedAlertViewController.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 04/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTNoteshelfAITokensConsumedAlertViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel?;
    @IBOutlet private weak var messageView: UITextView?;
    
    private var titleFont: UIFont {
        return UIFont.clearFaceFont(for: .medium, with: 28);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel?.attributedText = "noteshelf.ai.tokenCompleteTitle".aiLocalizedString.appendBetalogo(font: self.titleFont);
        self.messageView?.text = "noteshelf.ai.tokenCompleteMessage".aiLocalizedString;
    }
}
