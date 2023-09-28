//
//  FTIAPViewController.swift
//  Noteshelf3
//
//  Created by Siva on 14/03/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import StoreKit
import SafariServices

class FTIAPViewController: UIViewController {
    private var products: [SKProduct] = []
    var viewModel = FTIAPViewModel()

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?;
    @IBOutlet weak var upgradeButton: UIButton?;
    
    @IBOutlet weak var restorePurchaseButton: UIButton?;
    @IBOutlet weak var privacyButton: UIButton?;

    @IBOutlet weak var activityProgressView: UIView?;
    @IBOutlet weak var activityProgressHolderView: UIView?;

    @IBOutlet weak var titleLabel: UILabel?;
    @IBOutlet weak var subheadingLabel: UILabel?;
    @IBOutlet weak var messageLabel: UILabel?;

    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = CGSize(width: 700, height: 740);
        initializeActivityIndicator()

        self.setTitleToPurchaseButton(title:"")
        
        self.titleLabel?.font = UIFont.clearFaceFont(for: .medium, with: 44);
        self.subheadingLabel?.font = UIFont.appFont(for: .bold, with: 13);
        self.messageLabel?.font = UIFont.appFont(for: .regular, with: 17);
        
        self.titleLabel?.text = "iap.title".localized
        self.subheadingLabel?.text = "iap.onetimepurchase".localized
        self.messageLabel?.text = "iap.message".localized

        self.privacyButton?.setTitle("iap.privacy".localized, for: .normal);
        self.restorePurchaseButton?.setTitle("iap.restorePurchase".localized, for: .normal);
        if let upgradeButton = upgradeButton{
            upgradeButton.apply(to: upgradeButton, withScaleValue: 0.93)
        }
        viewModel.delegate = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let frame = self.upgradeButton?.frame {
            self.upgradeButton?.layer.cornerRadius = frame.height * 0.5;
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.viewDidSetup()
    }

    private func initializeActivityIndicator() {

    }

    private func showAlert(withMessage message: String,closeOnOk: Bool = false) {
        let alertController = UIAlertController(title: "Noteshelf", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: { [weak self] _ in
            if(closeOnOk) {
                self?.dismiss(animated: true);
            }
        }))
        self.present(alertController, animated: true, completion: nil)
    }

    @IBAction func purchaseAction(_ sender: Any) {
        track(EventName.premium_purchase_tap, screenName: ScreenName.iap)
        if let product = viewModel.getProduct(at: 0), !self.viewModel.purchase(product: product) {
            self.showAlert(withMessage: "iap.purchaseNotAllowed".localized)
        }
    }

    @IBAction func restoreAction(_ sender: Any) {
        track(EventName.premium_restorepurchase_tap, screenName: ScreenName.iap)
        viewModel.restorePurchases()
    }

    @IBAction func privacyAction(_ sender: Any) {
        track(EventName.premium_privacy_tap, screenName: ScreenName.iap)
        if let privacyURL = URL(string: "https://www.noteshelf.net/privacy.html") {
            let safariController = SFSafariViewController(url: privacyURL);
            safariController.modalPresentationStyle = .fullScreen
            safariController.modalTransitionStyle = .coverVertical
            self.present(safariController, animated: true);
        }
    }
        
    @IBAction func closeAction(_ sender: Any) {
        track(EventName.premium_close_tap, screenName: ScreenName.iap)
        self.dismiss(animated: true)
    }
    private func setTitleToPurchaseButton(title:String) {
        let attributedTitle = NSAttributedString(string: title,
                                                 attributes: [.font: UIFont.clearFaceFont(for: .medium, with: 20)])
        self.upgradeButton?.setAttributedTitle(attributedTitle, for: .normal)
    }
}

// MARK: - ViewModelDelegate
extension FTIAPViewController: FTIAPViewModelDelegate {
    func didfinishLoadingProducts() {
        if let product = viewModel.getProduct(at: 0) {
            guard let price = FTIAPManager.shared.getPriceFormatted(for: product) else { return }
            let title = String(format: "iap.purchase".localized, price);
            self.setTitleToPurchaseButton(title:title)
        }
    }

    func willStartLongProcess(_ action: FTIAPActionType) {
        self.activityProgressHolderView?.isHidden = false;
    }

    func didFinishLongProcess(_ action: FTIAPActionType) {
        self.activityProgressHolderView?.isHidden = true;
        if action == .purchase, FTIAPurchaseHelper.shared.isPremiumUser {
            self.dismiss(animated: true);
        }
    }

    func showIAPRelatedError(_ error: Error) {
        let message = error.localizedDescription
        showAlert(withMessage: message)
    }

    func didFinishRestoringPurchasesWithZeroProducts() {
        showAlert(withMessage: "iap.restoreSuccessWithNoPurchase".localized)
    }


    func didFinishRestoringPurchasedProducts() {
        showAlert(withMessage: "iap.restoreSuccess".localized,closeOnOk: true)
    }
}
