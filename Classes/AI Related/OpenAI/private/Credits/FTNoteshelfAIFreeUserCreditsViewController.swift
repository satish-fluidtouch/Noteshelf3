//
//  FTNoteshelfAIFreeUserCreditsViewController.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 06/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTNoteshelfAIFreeUserCreditsViewController: UIViewController {

    @IBOutlet private weak var upgradeNowButton: UIButton?;
    @IBOutlet private weak var creditTitle: UILabel?;
    @IBOutlet private weak var creditMessage: UILabel?;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.upgradeNowButton?.layer.cornerRadius = 12;
        
        let title = NSAttributedString(string:"noteshelf.ai.credit.upgradeNow".aiLocalizedString, attributes: [.font: UIFont.appFont(for: .bold, with: 13)]);
        self.upgradeNowButton?.setAttributedTitle(title, for: .normal);
                
        let tokensLeft = FTNoteshelfAITokenManager.shared.tokensLeft;
        if tokensLeft == 0 {
            self.creditTitle?.text = "noteshelf.ai.credit.nocredits".aiLocalizedString;
        }
        else if tokensLeft <= 5 {
            self.creditTitle?.text = "noteshelf.ai.credit.creditsRunningOut".aiLocalizedString;
        }
        else {
            self.creditTitle?.text = "noteshelf.ai.credit.bePremium".aiLocalizedString;
        }
        self.creditMessage?.text = "noteshelf.ai.credit.bePremiumInfo".aiLocalizedString;
    }
    

    @IBAction func upgradeNow(_ sender: Any?) {
        FTIAPurchaseHelper.shared.presentIAPIfNeeded(on: self);
    }
}
