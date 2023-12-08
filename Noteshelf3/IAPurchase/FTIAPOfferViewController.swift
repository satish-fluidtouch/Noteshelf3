//
//  FTIAPOfferViewController.swift
//  Noteshelf3
//
//  Created by Rakesh on 23/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import StoreKit
import SafariServices

class FTIAPOfferViewController: UIViewController {
    @IBOutlet weak var upgradeButton: UIButton?;
    @IBOutlet weak var restorePurchaseButton: UIButton?;
    @IBOutlet weak var privacyButton: UIButton?;

    @IBOutlet weak var topTitle: UILabel?
    @IBOutlet weak var titleLabel: UILabel?;
    @IBOutlet weak var messageLabel: UILabel?;

    @IBOutlet weak var miniTitleLabel: UILabel!
    @IBOutlet weak var subheadingLabel: UILabel?;

    private var discountedProduct: SKProduct?;
    private var originalProduct: SKProduct?;

    private weak var delegate: FTIAPContainerDelegate?

    static func instatiate(discountedProduct: SKProduct,
                           originalProduct: SKProduct,
                           delegate: FTIAPContainerDelegate?) -> FTIAPOfferViewController {
        let storyboard = UIStoryboard(name: "IAPEssentials", bundle: nil)
        guard let inAppPurchase = storyboard.instantiateViewController(withIdentifier: "FTIAPOfferViewController") as? FTIAPOfferViewController else {
            fatalError("FTIAPOfferViewController doesnt exist")
        }
        inAppPurchase.discountedProduct = discountedProduct
        inAppPurchase.originalProduct = originalProduct
        inAppPurchase.delegate = delegate
        return inAppPurchase
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = CGSize(width: 700, height: 740);
        self.attributedTitleText()
        self.messageLabel?.font = UIFont.appFont(for: .regular, with: 17);
        self.messageLabel?.text = "iap.messageNew".localized
        self.messageLabel?.addCharacterSpacing(kernValue: -0.41)
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
        miniTitleLabel?.text =  "iap.onetimepurchase".localized

        let variant = FTAppConfigHelper.sharedAppConfig().variantForOfferPremium()
        switch variant {
        case .priceOnButton:
            configurePriceOnButton()
        case .priceAboveButton:
            configurePriceAboveButton()
        }
        configureUI(priceLocation: variant)
    }

    func configurePriceAboveButton() {
        miniTitleLabel?.isHidden = true
        subheadingLabel?.isHidden = false
        self.upgradeButton?.titleLabel?.text = NSLocalizedString("iap.upgradeToPremiumNow", comment: "")
    }

    func configurePriceOnButton() {
        miniTitleLabel?.isHidden = false
        subheadingLabel?.isHidden = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let frame = self.upgradeButton?.frame {
            self.upgradeButton?.layer.cornerRadius = frame.height * 0.5;
        }
    }

    private func attributedTitleText(){
        let discountpercentage = 50
        let localisedText = NSLocalizedString("iap.bannerTitle1", comment: "Get Premium at %@ OFF")

        let offText =  String(format: NSLocalizedString("iap.discount.highlight", comment:""), "\(discountpercentage)%")


        let fullText =  String(format: localisedText,"\(discountpercentage)%")
        let range = (fullText as NSString).range(of: offText)

        let redAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.init(hexString: "#D6411c"),
            .font: UIFont(name: "SFProRounded-Bold", size: 36)!
        ]

        let blackAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black,
        ]
        let attributedString = NSMutableAttributedString(string: fullText, attributes: blackAttributes)
        attributedString.addAttributes(redAttributes, range: range)
        self.titleLabel?.attributedText = attributedString

        let mediumAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.clearFaceFont(for: .medium, with: 20.0)
        ]

        let boldAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.clearFaceFont(for: .bold, with: 20.0)
        ]
        let localisedString = NSLocalizedString("iap.toptitle", comment: "Noteshelf 2 users exclusive")
        let selectedRange = (localisedString as NSString).range(of: "Noteshelf 2")
        let attrString = NSMutableAttributedString(string: localisedString, attributes: mediumAttr)
        attrString.addAttributes(boldAttr, range: selectedRange)
        self.topTitle?.attributedText = attrString
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
        track(EventName.ns2premium_upgradenow_tap, screenName: ScreenName.iap)
        if let product = self.discountedProduct {
            self.delegate?.purchase(product: product)
        }
    }

    @IBAction func restoreAction(_ sender: Any) {
        track(EventName.ns2premium_restorepurchases_tap, screenName: ScreenName.iap)
        delegate?.restorePurchases()
    }

    @IBAction func privacyAction(_ sender: Any) {
        track(EventName.ns2premium_privacypolicy_tap, screenName: ScreenName.iap)
        if let privacyURL = URL(string: "https://www.noteshelf.net/privacy.html") {
            let safariController = SFSafariViewController(url: privacyURL);
            safariController.modalPresentationStyle = .fullScreen
            safariController.modalTransitionStyle = .coverVertical
            self.present(safariController, animated: true);
        }
    }

    @IBAction func closeAction(_ sender: Any) {
        track(EventName.ns2premium_close_tap, screenName: ScreenName.iap)
        self.dismiss(animated: true)
    }
    private func setTitleToPurchaseButton(title:String) {
        let attributedTitle = NSAttributedString(string: title,
                                                 attributes: self.upgradeTitleAttributes)
        self.upgradeButton?.setAttributedTitle(attributedTitle, for: .normal)
    }
}

// MARK: - ViewModelDelegate
extension FTIAPOfferViewController {
    func configureUI(priceLocation: OfferPriceLocation) {
        guard let ns3product = originalProduct,
              let ns3Price = FTIAPManager.shared.getPriceFormatted(for: ns3product),
              let ns2Product = discountedProduct,
              let ns2Price = FTIAPManager.shared.getPriceFormatted(for: ns2Product) else {
            return
        }
        //This code needs be refacotored
        if priceLocation == .priceAboveButton {
            let iapPurchaseTitle = "iap.onetimepurchasenew".localized;

            let atts: [NSAttributedString.Key:Any] = self.subHeadlineTitleAttributes;
            let attributedTitle = NSMutableAttributedString(string: iapPurchaseTitle,attributes:atts);
            if let range = iapPurchaseTitle.range(of: "%@") {
                var strikeThroughAttr : [NSAttributedString.Key:Any] = atts;
                strikeThroughAttr[.strikethroughStyle] =  NSUnderlineStyle.single.rawValue;
                strikeThroughAttr[.strikethroughColor] =  UIColor.appColor(.black50);
                strikeThroughAttr[.foregroundColor] = UIColor.appColor(.black50)
                strikeThroughAttr[.font] = UIFont.appFont(for: .medium, with: 13)
                let priceString = NSMutableAttributedString(string: ns3Price,attributes: strikeThroughAttr);
                priceString.append(NSAttributedString(string: " ", attributes: atts));
                priceString.append(NSAttributedString(string: "(50% Off)", attributes: atts));
                priceString.append(NSAttributedString(string: " ", attributes: atts));
                priceString.append(NSAttributedString(string: ns2Price,attributes: atts));
                let nsRange = NSRange(range,in: iapPurchaseTitle);
                attributedTitle.replaceCharacters(in: nsRange, with: priceString)
                attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.black.withAlphaComponent(0.5), range: nsRange)
                self.subheadingLabel?.attributedText = attributedTitle
            }
        } else {
            let upgradeAttrs: [NSAttributedString.Key:Any] = self.upgradeTitleAttributes;
            let iapPurchaseButtonTitle = "iap.purchase".localized;
            let purchaseAttributedTitle = NSMutableAttributedString(string: iapPurchaseButtonTitle,attributes: upgradeAttrs);
            if let range = iapPurchaseButtonTitle.range(of: "%@") {
                var strikeThroughAttr : [NSAttributedString.Key:Any] = upgradeAttrs;
                strikeThroughAttr[.strikethroughStyle] =  NSUnderlineStyle.single.rawValue;
                strikeThroughAttr[.strikethroughColor] =  UIColor.appColor(.white60);
                strikeThroughAttr[.foregroundColor] = UIColor.appColor(.white60)
                strikeThroughAttr[.font] = UIFont.clearFaceFont(for: .medium, with: 20)
                let priceString = NSMutableAttributedString(string: ns3Price,attributes: strikeThroughAttr);
                priceString.append(NSAttributedString(string: " ", attributes: upgradeAttrs));
                priceString.append(NSAttributedString(string: ns2Price,attributes: upgradeAttrs));
                let nsRange = NSRange(range,in: iapPurchaseButtonTitle);
                purchaseAttributedTitle.replaceCharacters(in: nsRange, with: priceString)
                self.upgradeButton?.setAttributedTitle(purchaseAttributedTitle, for: .normal)
            }
        }
    }
}

private extension FTIAPOfferViewController {
    var subHeadlineTitleAttributes: [NSAttributedString.Key : Any] {
        return [.font: UIFont.appFont(for: .medium, with: 13)];
    }
    var upgradeTitleAttributes: [NSAttributedString.Key : Any] {
        return [.font: UIFont.clearFaceFont(for: .medium, with: 20)];
    }

    func discountedPercentage(_ ns3Product: SKProduct, ns2Product: SKProduct) {
        let ns2Value = ns2Product.price.floatValue;
        let ns3Value = ns3Product.price.floatValue;
        let percentage = ((Int)((ns2Value/ns3Value) * 10))*10
        debugPrint("roundupvalue: \(percentage)");
    }
}
