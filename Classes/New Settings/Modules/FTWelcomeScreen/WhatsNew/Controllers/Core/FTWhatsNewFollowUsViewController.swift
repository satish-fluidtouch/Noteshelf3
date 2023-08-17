//
//  FTWhatsNewFollowUsViewController.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 12/04/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTWhatsNewFollowUsViewController: FTWhatsNewSlideViewController {
    var index : Int = 0
    @IBOutlet private weak var socialBannerImageView: UIImageView?
    private var imageArray: [UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for i in 1...5 {
            self.imageArray.append(UIImage(named: "social-media-joinus-"+"\(i)")!)
        }
        self.actionButton1?.layer.cornerRadius = 23
        self.actionButton1?.layer.borderColor = UIColor(hexString: "cbcbcb").cgColor
        self.actionButton1?.layer.borderWidth = 1.0
        
//        self.helpTitle?.textColor = UIColor(hexString: "000000");
//        self.helpMessage?.textColor = UIColor(hexString: "151515");
        
        self.helpTitle?.styleText = FTWhatsNewLocalizedString("JoinUsTitle", comment: "Follow Us");
        self.helpMessage?.styledAttributedTextForWhatsNewHelpMessage = self.attributedMessageText(forMessage: FTWhatsNewLocalizedString("JoinUsDescription", comment: ""), withLineHeight: 26);
        
        self.actionButton1?.setTitle(FTWhatsNewLocalizedString("MayBeLater", comment: ""), for: .normal);
        self.actionButton2?.setTitle(FTWhatsNewLocalizedString("FollowUs", comment: ""), for: .normal);
    }
    @IBAction func mayBeLaterClicked() {
        FTWhatsNewManger.setAsWhatsNewViewed();
        self.delegate.close();
        track("Settings_WhatsNew_FollowLater", params: [:], screenName: FTScreenNames.whatsNew)
    }
    override func playAnimation() {
        track("whatsnew_joinus_instagram", params: [:], screenName: FTScreenNames.whatsNew)
        self.startAnimating()
    }
    override func stopAnimation() {
        self.index = 0
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.socialBannerImageView?.layer.removeAllAnimations()
    }
    @IBAction func followUsClicked() {
        if let instagramURL = URL.init(string: instagramURL) {
            UIApplication.shared.open(instagramURL, options: [:], completionHandler: nil);
            track("Settings_WhatsNew_FollowUs", params: [:], screenName: FTScreenNames.whatsNew)
        }
    }
    @objc private func startAnimating() {
        if let imgView = self.socialBannerImageView {
            UIView.transition(with: imgView, duration: 0.6, options: .transitionCrossDissolve, animations: {
                self.socialBannerImageView?.image = self.imageArray[self.index]
            }) { (success) in
                if success {
                    self.index += 1
                    if self.index > (self.imageArray.count - 1) {
                        self.index = 0
                    }
                    self.perform(#selector(self.startAnimating), with: nil, afterDelay: 2.0)
                }
            }
        }
    }
}
