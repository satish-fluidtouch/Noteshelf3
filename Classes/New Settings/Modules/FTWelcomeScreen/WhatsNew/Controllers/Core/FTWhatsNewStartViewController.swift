//
//  FTWhatsNewStartViewController.swift
//  Noteshelf
//
//  Created by Siva on 10/11/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import WebKit
import FTStyles

class FTWhatsNewStartViewController: FTWhatsNewSlideViewController {
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad();
        track("whatsnew_first_screen", params: [:], screenName: FTScreenNames.whatsNew)

        self.helpTitle?.textColor = UIColor.appColor(.accent)
        self.helpMessage?.textColor = UIColor.label

        self.helpTitle?.styleText = FTWhatsNewLocalizedString("WhatsNewStartTitle", comment: "WHAT’S NEW");
        self.helpMessage?.styledAttributedTextForWhatsNewHelpMessage = self.attributedMessageText(forMessage: String(format: "%@\n%@\n%@\n%@", FTWhatsNewLocalizedString("WhatsNewStudentPackTitle", comment: "New Student Templates"), NSLocalizedString("QuickNote", comment: "Quick Note"),
            FTWhatsNewLocalizedString("WhatsNewReadModeFeature", comment: "Read Only Mode"),
            NSLocalizedString("HoldToConvertToShape", comment: "Hold To Convert to Shape")), withLineHeight: 36)
        self.helpTitle?.font = UIFont.montserratFont(for: .extraBold, with: 70.0)
        self.helpMessage?.font = UIFont.init(name: "HelveticaNeue-Medium", size: 28)

        self.actionButton1?.setTitle(FTWhatsNewLocalizedString("SeeWhatsNew", comment: "See What’s New"), for: .normal);
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: self.helpTitle);
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated);
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Custom
    @IBAction func seeWhatsNewClicked() {
        self.delegate.whatsNewSlideViewControllerDidClickNext(whatsNewSlideViewController: self);
        track("Settings_WhatsNew_SeeWhatsNew", params: [:], screenName: FTScreenNames.whatsNew)
    }
}
