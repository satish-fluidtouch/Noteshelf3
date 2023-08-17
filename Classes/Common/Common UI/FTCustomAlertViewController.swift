//
//  FTCustomAlertViewController.swift
//  Noteshelf
//
//  Created by Narayana on 11/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTCustomAlertViewDelegate: AnyObject {
    func didTapFirstButton()
    func didTapSecondButton(alertSourceView: UIView?)
}

enum FTCustomAlertFlow {
    case colorPicker
    case others
}

 class FTCustomAlertViewController: UIViewController {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var firstButton: UIButton!
    @IBOutlet private weak var secondButton: UIButton!
    @IBOutlet weak var alertView: UIView!

    weak var delegate: FTCustomAlertViewDelegate?
    weak var sourceView: UIView?
     var customAlertFlow: FTCustomAlertFlow = .others
     
     @IBOutlet weak var alertViewWidthConstraint: NSLayoutConstraint!
     
    override func viewDidLoad() {
        super.viewDidLoad()
        self.firstButton.setInnerBorder(withBorderWidth: 1.0, withColor: UIColor.black.withAlphaComponent(0.1))
        self.configureAlertView()
    }
     
     private func configureAlertView() {
         alertView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
         alertView.layer.shadowOpacity =  1.0
         alertView.layer.shadowRadius =  10.0
         alertView.layer.shadowOffset =  CGSize(width: 0.0, height: 0.0)
         if let presentingVC = self.presentingViewController, presentingVC.isRegularClass() && self.customAlertFlow == .colorPicker  {
             self.alertViewWidthConstraint.constant = 400.0
         }
     }
     
     func configureCustomAlert(alertTitle: String, message: String, firstBtnTitle: String, secondBtnTitle: String) {
        self.titleLabel.text = alertTitle
        self.messageLabel.text = message
        self.firstButton.setTitle(firstBtnTitle, for: .normal)
        self.secondButton.setTitle(secondBtnTitle, for: .normal)
    }
    
    @IBAction func firstBtnTapped(_ sender: Any) {
        self.delegate?.didTapFirstButton()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func secondBtnTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        self.delegate?.didTapSecondButton(alertSourceView: self.sourceView)
    }
    
     class func presentCustomAlert(by view: UIView, on controller: UIViewController, flow: FTCustomAlertFlow = .others) -> FTCustomAlertViewController {
        let storyboard = UIStoryboard(name: "FTCommon", bundle: Bundle(for: FTCustomAlertViewController.self))
        guard let customAlertVc = storyboard.instantiateViewController(withIdentifier: "FTCustomAlertViewController") as? FTCustomAlertViewController else {
            fatalError("Could not find FTCustomAlertViewController")
        }
            customAlertVc.providesPresentationContextTransitionStyle = true
            customAlertVc.definesPresentationContext = true
            customAlertVc.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            customAlertVc.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            customAlertVc.sourceView = view
            customAlertVc.customAlertFlow = flow
            controller.present(customAlertVc, animated: true, completion: nil)
            return customAlertVc
    }
    
}
