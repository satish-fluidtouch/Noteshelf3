//
//  FTNoteshelfAIFoorterViewController.swift
//  Sample AI
//
//  Created by Amar Udupa on 28/07/23.
//

import UIKit
import SafariServices

enum FTAIFooterMode: Int {
    case noteshelfAiBeta,sendFeedback,noFooter;
}

class FTNoteshelfAIFooterViewController: UIViewController {
    @IBOutlet private weak var learnMore: UIButton?;
    @IBOutlet private weak var bePremiumUser: UIButton?;
    @IBOutlet private weak var sendFeedback: UIButton?;

    var footermode: FTAIFooterMode = .noteshelfAiBeta {
        didSet {
            switch self.footermode {
            case .noFooter:
                self.learnMore?.isHidden = true;
                self.sendFeedback?.isHidden = true;
            case .noteshelfAiBeta:
                self.sendFeedback?.isHidden = true;
                self.learnMore?.isHidden = false;
            case .sendFeedback:
                self.learnMore?.isHidden = true;
                self.sendFeedback?.isHidden = false;
            }
            self.bePremiumUser?.isHidden = true;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.footermode = .noteshelfAiBeta;
        
        let defaultFont = UIFont.systemFont(ofSize: 13);
        let attrTitle = NSAttributedString(string: "noteshelf.ai.noteshelfAILearnMore".aiLocalizedString, attributes: [.font: defaultFont]);
        
        self.learnMore?.setAttributedTitle(attrTitle, for: .normal);
        self.learnMore?.configuration?.imagePadding = 5;

        let style = NSMutableParagraphStyle();
        style.alignment = .center;
        let _attrTitle = NSAttributedString(string: "noteshelf.ai.handwriteMessage".aiLocalizedString, attributes: [
            .font: defaultFont
            ,.paragraphStyle : style
        ]);
        self.bePremiumUser?.setAttributedTitle(_attrTitle, for: .normal);
                
        self.sendFeedback?.configuration?.title = "noteshelf.ai.sendFeedback".aiLocalizedString;
        self.sendFeedback?.titleLabel?.font = defaultFont
    }
    
    @IBAction func showNoteshelfAILearnmore(_ sender: Any?) {
        let openAIURL = "https://medium.com/noteshelf/introducing-noteshelf-ai-beta-b629dea9964b"; //"https://noteshelf-support.fluidtouch.biz/hc/en-us/articles/21713907764505"
        if let url = URL(string: openAIURL) {
#if targetEnvironment(macCatalyst)
            UIApplication.shared.open(url);
#else
            //            FTZenDeskManager.shared.showArticle("21713907764505", in: self.parent ?? self, completion: nil);
            let safariController = SFSafariViewController(url: url);
            safariController.modalPresentationStyle = .overFullScreen
            (self.parent ?? self).present(safariController, animated: true);
#endif
        }
    }

    @IBAction func sendFeedback(_ sender: Any?) {
        FTZenDeskManager.shared.showSupportContactUsScreen(controller: self.parent ?? self
                                                           , defaultSubject: "Noteshelf-AI Feedback"
                                                           , extraTags: ["Noteshelf-AI"]);
    }
    
    @IBAction func bePremiumButtonAction(_ sender: Any?) {
        FTIAPurchaseHelper.shared.presentIAPIfNeeded(on: self.parent ?? self);
    }
}
