//
//  FTIAPOfferCampaignViewController.swift
//  Noteshelf3
//
//  Created by Fluid Touch on 18/04/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import StoreKit
import SafariServices

class FTIAPOfferCampaignViewController: UIViewController {
    @IBOutlet weak var upgradeButton: UIButton?;
    @IBOutlet weak var restorePurchaseButton: UIButton?;
    @IBOutlet weak var privacyButton: UIButton?;

    @IBOutlet weak var topTitle: UILabel?
    @IBOutlet weak var titleLabel: UILabel?;
    @IBOutlet weak var messageLabel: UILabel?;

    @IBOutlet weak var subheadingLabel: UILabel?;

    private var originalProduct: SKProduct?;

    private weak var delegate: FTIAPContainerDelegate?

    static func instatiate(originalProduct: SKProduct,
                           delegate: FTIAPContainerDelegate?) -> FTIAPOfferCampaignViewController {
        let storyboard = UIStoryboard(name: "IAPEssentials", bundle: nil)
        guard let inAppPurchase = storyboard.instantiateViewController(withIdentifier: "FTIAPOfferCampaignViewController") as? FTIAPOfferCampaignViewController else {
            fatalError("FTIAPOfferCampaignViewController doesnt exist")
        }
        inAppPurchase.originalProduct = originalProduct
        inAppPurchase.delegate = delegate
        return inAppPurchase
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = CGSize(width: 700, height: 740);
        self.attributedTitleText()
        updateDescriptionLabel()
        self.upgradeButton?.layer.shadowColor = UIColor.black.cgColor
        self.upgradeButton?.layer.shadowOpacity = 0.2
        self.upgradeButton?.layer.shadowRadius = 8.0
        self.upgradeButton?.layer.shadowOffset = CGSize(width: 0, height: 12.0)
        self.privacyButton?.titleLabel?.text = "iap.privacy".localized
        self.restorePurchaseButton?.titleLabel?.text = "iap.restorePurchase".localized
        if let upgradeButton = upgradeButton{
            upgradeButton.apply(to: upgradeButton, withScaleValue: 0.93)
        }
        configurePriceAboveButton()
        configureUI(priceLocation: OfferPriceLocation.priceAboveButton)
    }
    
    private func updateDescriptionLabel() {
        let localisedString = NSLocalizedString("iap.campaign.description", comment: "Noteshelf Premium")
        let boldText = "iap.campaign.description.placeholder".localized
        let font = UIFont.appFont(for: .bold, with: 17)
        self.messageLabel?.attributedText = localisedString.replaceAndBold(substring: "%@", with: boldText, using: font, lineSpacing: 5)
    }

    func configurePriceAboveButton() {
        subheadingLabel?.isHidden = false
        setTitleToPurchaseButton(title: NSLocalizedString("iap.upgradeToPremiumNow", comment: ""))
    }

    func configurePriceOnButton() {
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
        let localisedString = NSLocalizedString("iap.campaign.title", comment: "Earth day Offer")
        let boldText = "iap.earthday.title".localized
        let font = UIFont.clearFaceFont(for: .bold, with: 32)

        self.topTitle?.attributedText = localisedString.replaceAndBold(substring: "%@", with: boldText, using: font)
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
        if let product = self.originalProduct {
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
extension FTIAPOfferCampaignViewController {
    func configureUI(priceLocation: OfferPriceLocation) {
        guard let ns3product = originalProduct,
        let ns3Price = FTIAPManager.shared.getPriceFormatted(for: ns3product) else {
            return
        }
        let iapPurchaseTitle = "iap.onetimepurchasenew".localized;
        
        let atts: [NSAttributedString.Key:Any] = self.subHeadlineTitleAttributes;
        let attributedTitle = NSMutableAttributedString(string: iapPurchaseTitle,attributes:atts);
        if let range = iapPurchaseTitle.range(of: "%@") {
            let priceString = NSMutableAttributedString(string: ns3Price + " / ",attributes: atts);
            let nsRange = NSRange(range,in: iapPurchaseTitle);
            attributedTitle.replaceCharacters(in: nsRange, with: priceString)
            self.subheadingLabel?.attributedText = attributedTitle
        }
    }
}

private extension FTIAPOfferCampaignViewController {
    var subHeadlineTitleAttributes: [NSAttributedString.Key : Any] {
        return [.font: UIFont.appFont(for: .bold, with: 13)];
    }
    
    var upgradeTitleAttributes: [NSAttributedString.Key : Any] {
        return [.font: UIFont.clearFaceFont(for: .medium, with: 20)];
    }

    func discountedPercentage(_ ns3Product: SKProduct, ns2Product: SKProduct) -> Int {
        let ns2Value = ns2Product.price.floatValue;
        let ns3Value = ns3Product.price.floatValue;
        let roundedValue = round(((ns3Value-ns2Value)/ns3Value) * 10);
        let percentage = (Int)(roundedValue) * 10
        return percentage;
    }
}

extension String {
    func replaceAndBold(substring: String, with boldText: String, using font: UIFont, lineSpacing: CGFloat? = nil) -> NSAttributedString? {
        guard let range = self.range(of: substring) else {
            return nil
        }
        let mutableAttributedString = NSMutableAttributedString(string: self)
        mutableAttributedString.addAttribute(.font, value: font, range: NSRange(range, in: self))
        mutableAttributedString.replaceCharacters(in: NSRange(range, in: self), with: boldText)
        if let lineSpacing {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing
            mutableAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: mutableAttributedString.length))
            paragraphStyle.alignment = NSTextAlignment.center
        }
        return mutableAttributedString
    }
}
