//
//  FTNoteshelfAIPremiumUserCreditsViewController.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 06/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Combine

class FTNoteshelfAIPremiumUserCreditsViewController: UIViewController {

    @IBOutlet private weak var progressBar: UIProgressView?;
    @IBOutlet private weak var creditsInfo: UILabel?;
    @IBOutlet private weak var creditsMessage: UILabel?;
    
    private var premiumCancellableEvent: AnyCancellable?;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !FTIAPManager.shared.premiumUser.isPremiumUser {
            premiumCancellableEvent = FTIAPManager.shared.premiumUser.$isPremiumUser.sink { [weak self] isPremium in
                self?.updateUI();
            }
        }
        else {
            self.updateUI();
        }
    }
    
    deinit {
        premiumCancellableEvent?.cancel();
        premiumCancellableEvent = nil;
    }
    
    private func updateUI() {
        let consumed = FTNoteshelfAITokenManager.shared.consumedTokens;
        let tokensLeft = FTNoteshelfAITokenManager.shared.tokensLeft;
        let maxTokens = FTNoteshelfAITokenManager.shared.maxAllowedTokens;
        
        let isPremiumUser = FTIAPManager.shared.premiumUser.isPremiumUser;
        if tokensLeft <= 5 {
            self.view.backgroundColor = isPremiumUser ? UIColor(named: "credits_warn_bg") : UIColor.clear;
            self.progressBar?.progressTintColor = UIColor(named: "credits_progress_warn");
        }
        else {
            self.view.backgroundColor = isPremiumUser ? UIColor(named: "credits_normal_bg") : UIColor.clear;
            self.progressBar?.progressTintColor = UIColor(named: "credits_progress_normal");
        }
        self.progressBar?.progress = Float(consumed)/Float(maxTokens);
        self.creditsInfo?.text = String(format: "noteshelf.ai.credit.details".aiLocalizedString, tokensLeft,maxTokens);
        self.creditsMessage?.isHidden = !FTIAPManager.shared.premiumUser.isPremiumUser
        self.creditsMessage?.text = String(format: "noteshelf.ai.credit.moreinfo".aiLocalizedString,FTNoteshelfAITokenManager.shared.daysLeftForTokenReset());
    }
}
