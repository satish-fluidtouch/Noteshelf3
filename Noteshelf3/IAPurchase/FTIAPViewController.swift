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

    private var productToBuy: SKProduct?;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = CGSize(width: 700, height: 740);
        initializeActivityIndicator()

        self.attributedTitleText()
//        self.titleLabel?.font = UIFont.clearFaceFont(for: .bold, with: 44);
        self.messageLabel?.font = UIFont.appFont(for: .regular, with: 17);
        
        self.messageLabel?.text = "iap.messageNew".localized
        self.upgradeButton?.titleLabel?.text = NSLocalizedString("iap.upgradeToPremiumNow", comment: "")
        self.upgradeButton?.titleLabel?.font = UIFont.clearFaceFont(for: .medium, with: 20)
        self.upgradeButton?.layer.shadowColor = UIColor.black.cgColor
        self.upgradeButton?.layer.shadowOpacity = 0.2
        self.upgradeButton?.layer.shadowRadius = 8.0
        self.upgradeButton?.layer.shadowOffset = CGSize(width: 0, height: 12.0)

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

    private func attributedTitleText(){
        let discountpercentage = 50
        let localisedText = NSLocalizedString("iap.bannerTitle1", comment: "Get Premium at %@ OFF")
        let range = (localisedText as NSString).range(of: "%@")

        let title1 =  String(format: localisedText,"\(discountpercentage)%")
        let title2 = NSLocalizedString("iap.bannerTitle2", comment: "")
        let fullText = "\(title1) \n \(title2)"
        let redAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.red
        ]
        let blackAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black
        ]
        let attributedString = NSMutableAttributedString(string: fullText, attributes: blackAttributes)
        attributedString.addAttributes(redAttributes, range: NSRange(location: range.location, length: range.length + 1))

        attributedString.addAttributes(redAttributes, range: range)
        self.titleLabel?.attributedText = attributedString
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
        if let product = self.productToBuy, !self.viewModel.purchase(product: product) {
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
                                                 attributes: self.upgradeTitleAttributes)
        self.subheadingLabel?.attributedText = attributedTitle
    }
}

// MARK: - ViewModelDelegate
extension FTIAPViewController: FTIAPViewModelDelegate {
    func didfinishLoadingProducts() {
        guard let ns3product = viewModel.ns3PremiumProduct()
        ,let ns3Price = FTIAPManager.shared.getPriceFormatted(for: ns3product) else {
            return;
        }
        
        let iapPurchaseTitle = "iap.onetimepurchasenew".localized;
        
        if let ns2Product = viewModel.ns3PremiumForNS2UserProduct()
            ,let ns2Price = FTIAPManager.shared.getPriceFormatted(for: ns2Product) {
            productToBuy = ns2Product;

            let atts: [NSAttributedString.Key:Any] = self.upgradeTitleAttributes;
            let attributedTitle = NSMutableAttributedString(string: iapPurchaseTitle,attributes:atts);
            
            var strikeThroughAttr : [NSAttributedString.Key:Any] = atts;
            strikeThroughAttr[.strikethroughStyle] =  NSUnderlineStyle.single.rawValue;
            strikeThroughAttr[.strikethroughColor] =  UIColor.black.withAlphaComponent(0.5);
            strikeThroughAttr[.foregroundColor] = UIColor.black.withAlphaComponent(0.5)

            let priceString = NSMutableAttributedString(string: ns3Price,attributes: strikeThroughAttr);
            priceString.append(NSAttributedString(string: " ", attributes: atts));
            priceString.append(NSAttributedString(string: ns2Price,attributes: atts));

            if let range = iapPurchaseTitle.range(of: "%@") {
                let nsRange = NSRange(range,in: iapPurchaseTitle);
                attributedTitle.replaceCharacters(in: nsRange, with: priceString)
                attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.black.withAlphaComponent(0.5), range: nsRange)
                self.subheadingLabel?.attributedText = attributedTitle
                productToBuy = ns2Product;
            }
            else {
                let title = String(format: iapPurchaseTitle, ns2Price);
                self.setTitleToPurchaseButton(title:title)
            }
//            self.discountedPercentage(ns3product, ns2Product: ns2Product);
        }
        else {
            productToBuy = ns3product;
            let title = String(format: iapPurchaseTitle, ns3Price);
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

private extension FTIAPViewController {
    var upgradeTitleAttributes: [NSAttributedString.Key : Any] {
        return [.font: UIFont.appFont(for: .medium, with: 13)];
    }
    
    func discountedPercentage(_ ns3Product: SKProduct, ns2Product: SKProduct) {
        let ns2Value = ns2Product.price.floatValue;
        let ns3Value = ns3Product.price.floatValue;
        let percentage = ((Int)((ns2Value/ns3Value) * 10))*10
        debugPrint("roundupvalue: \(percentage)");
    }
}
