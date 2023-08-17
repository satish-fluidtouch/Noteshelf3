//
//  FTQuickCreateInfoTipViewController.swift
//  Noteshelf
//
//  Created by Narayana on 07/01/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTQuickNoteChangeTemplateDelegate: AnyObject {
    func didChangeTemplate(from viewController:  FTQuickCreateInfoTipViewController)
}

class FTQuickCreateInfoTipViewController: UIViewController {
    
    @IBOutlet weak var infoTipView: FTInfoTipView!
    
    weak var delegate: FTQuickNoteChangeTemplateDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.infoTipView.configureTextAndTipImage(titleStr: NSLocalizedString("QuickCreateNoteInfoTipTitle", comment: "More Paper Templates Here"), subTitleStr: NSLocalizedString("QuickCreateNoteInfoTipSubTitle", comment: "Want to change the current page template? Tap here to find more options."), firstBtnStr: NSLocalizedString("Close", comment: "Close"), secondBtnStr: NSLocalizedString("ChangeTemplate", comment: "Change Template"), imageName: "popOverPageTemp")
        self.infoTipView.configureUI(with: .morePaperTemplates)
        self.infoTipView.infoTipDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.preferredContentSize = CGSize.init(width: 306, height: 131)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.preferredContentSize = CGSize.init(width: 306, height: self.infoTipView.contentView.frame.height)
    }

    private func restrictQuickCreateInfoTipToShow() {
        UserDefaults.standard.setValue(false, forKey: "quickCreateTipToShow")
        UserDefaults.standard.setValue(false, forKey: "IsQuickCreateFirstTimeTap")
    }
}

extension FTQuickCreateInfoTipViewController: FTInfoTipDelegate {
    func didClickOnButton(ofType actionType: FTInfoTipButtonType) {
        if actionType == .close {
            self.restrictQuickCreateInfoTipToShow()
            self.dismiss(animated: true, completion: nil)
        } else if actionType == .changeTemplate {
            self.restrictQuickCreateInfoTipToShow()
            self.delegate?.didChangeTemplate(from: self)
            track("Onboarding_ChangeTemplate", params: [:], screenName: FTScreenNames.noteBookOptions)
        }
    }
}

extension FTQuickCreateInfoTipViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        if self.isRegularClass() {
            return controller.presentationStyle
        }
        if UIDevice.current.isIpad() {
            self.dismiss(animated: true, completion: nil)
        }
        return .none
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        self.restrictQuickCreateInfoTipToShow()
        return true
    }
}
