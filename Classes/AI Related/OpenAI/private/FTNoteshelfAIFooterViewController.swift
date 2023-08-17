//
//  FTNoteshelfAIFoorterViewController.swift
//  Sample AI
//
//  Created by Amar Udupa on 28/07/23.
//

import UIKit

enum FTAIFooterMode: Int {
    case noteshelfAiBeta,sendFeedback;
}

class FTNoteshelfAIFooterViewController: UIViewController {
    @IBOutlet private weak var learnMore: UIButton?;
    @IBOutlet private weak var sendFeedback: UIButton?;

    var footermode: FTAIFooterMode = .noteshelfAiBeta {
        didSet {
            self.learnMore?.isHidden = self.footermode == .sendFeedback
            self.sendFeedback?.isHidden = self.footermode == .noteshelfAiBeta
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.footermode = .noteshelfAiBeta;
        
        let defaultFont = UIFont.systemFont(ofSize: 13);
        let attrTitle = "noteshelf.ai.noteshelfAI".aiLocalizedString.appendBetalogo(font: defaultFont);
        self.learnMore?.setAttributedTitle(attrTitle, for: .normal);
        self.learnMore?.configuration?.imagePadding = 5;

        self.sendFeedback?.setTitle("noteshelf.ai.sendFeedback".aiLocalizedString, for: .normal);
    }
    
    @IBAction func showNoteshelfAILearnmore(_ sender: Any?) {
#if targetEnvironment(macCatalyst)
        if let url = URL(string: "https://noteshelf-support.fluidtouch.biz/hc/en-us/articles/21713907764505") {
            UIApplication.shared.open(url);
        }
#else
        FTZenDeskManager.shared.showArticle("21713907764505", in: self.parent ?? self, completion: nil);
#endif
    }

    @IBAction func sendFeedback(_ sender: Any?) {
        FTZenDeskManager.shared.showSupportContactUsScreen(controller: self.parent ?? self
                                                           , defaultSubject: "Noteshelf-AI Feedback"
                                                           , extraTags: ["Noteshelf-AI"]);
    }
}
