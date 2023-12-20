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

    @IBOutlet weak var upgradeButton: UIButton?;
    
    @IBOutlet weak var restorePurchaseButton: UIButton?;
    @IBOutlet weak var privacyButton: UIButton?;

    @IBOutlet weak var titleLabel: UILabel?;
    @IBOutlet weak var subheadingLabel: UILabel?;
    @IBOutlet weak var messageLabel: UILabel?;

    private var productToBuy: SKProduct?
    private weak var delegate: FTIAPContainerDelegate?

    static func instatiate(with product: SKProduct, delegate: FTIAPContainerDelegate) -> FTIAPViewController {
        let storyboard = UIStoryboard(name: "IAPEssentials", bundle: nil)
        guard let inAppPurchase = storyboard.instantiateViewController(withIdentifier: "FTIAPViewController") as? FTIAPViewController else {
            fatalError("FTIAPViewController doesnt exist")
        }
        inAppPurchase.productToBuy = product
        inAppPurchase.delegate = delegate
        return inAppPurchase
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = CGSize(width: 700, height: 740);

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

        configureUI()
    }

    func configureUI() {
        guard let ns3product = productToBuy,
              let ns3Price = FTIAPManager.shared.getPriceFormatted(for: ns3product) else {
            return;
        }

        let iapPurchaseTitle = "iap.purchase".localized;
        let title = String(format: iapPurchaseTitle, ns3Price);
        self.setTitleToPurchaseButton(title:title)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let frame = self.upgradeButton?.frame {
            self.upgradeButton?.layer.cornerRadius = frame.height * 0.5;
        }
    }

    @IBAction func purchaseAction(_ sender: Any) {
        track(EventName.premium_purchase_tap, screenName: ScreenName.iap)
        if let product = self.productToBuy {
            delegate?.purchase(product: product)
        }
    }

    @IBAction func restoreAction(_ sender: Any) {
        track(EventName.premium_restorepurchase_tap, screenName: ScreenName.iap)
        delegate?.restorePurchases()
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
                                                 attributes: self.upgradeTitleAttributes)
        self.upgradeButton?.setAttributedTitle(attributedTitle, for: .normal)
    }
}

private extension FTIAPViewController {
    var upgradeTitleAttributes: [NSAttributedString.Key : Any] {
        return [.font: UIFont.clearFaceFont(for: .medium, with: 20)];
    }
    
    func discountedPercentage(_ ns3Product: SKProduct, ns2Product: SKProduct) -> Int {
        let ns2Value = ns2Product.price.floatValue;
        let ns3Value = ns3Product.price.floatValue;
        let roundedValue = round((ns2Value/ns3Value) * 10);
        let percentage = (Int)(roundedValue) * 10
        return percentage;
    }
}
