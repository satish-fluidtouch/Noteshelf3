//
//  FTAiPrivacyConsetViewController.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 03/06/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SafariServices
protocol FTAiPrivacyConsetViewControllerProtocal: AnyObject {
    func showAiScreen()
}

class FTAiPrivacyConsetViewController: UIViewController {

    @IBOutlet weak private var bgView: UIView!
    @IBOutlet weak private var titleLbl: UILabel!
    @IBOutlet weak private var descriptionLbl: UILabel!
    @IBOutlet weak private var tickBtn: UIButton!
    @IBOutlet weak private var privacyPolicy: UILabel!
    @IBOutlet weak private var cancelBtn: UIButton!
    @IBOutlet weak private var saveBtn: UIButton!
    @IBOutlet weak private var scrollView: UIScrollView!
    
    weak var delegate : FTAiPrivacyConsetViewControllerProtocal?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUi()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let scrollFrameHeight = self.scrollView.frame.size.height
        let scrollContentHeight = self.scrollView.contentSize.height
        
        if scrollContentHeight > scrollFrameHeight {
            scrollView.isScrollEnabled = true
        }else {
            scrollView.isScrollEnabled = false
        }
    }
    
    @IBAction func tickBtnAction(_ sender: UIButton){
        if sender.tag == 0 {
            setUptickBtn(status:false)
            sender.tag = 1
        }else if sender.tag == 1{
            setUptickBtn(status:true)
            sender.tag = 0
        }
    }
    
    @IBAction func cancelBtnAction(_ sender: UIButton){
        self.dismiss(animated:true)
    }
    
    @IBAction func saveBtnAction(_ sender: UIButton){
       UserDefaults.standard.set(false, forKey: "shouldAiPolicyAccepte")
       self.dismiss(animated:false)
       self.delegate?.showAiScreen()
    }
    
    private func setUpUi() {
        self.cancelBtn.layer.borderColor  = UIColor.appColor(.accent).cgColor
        self.cancelBtn.layer.borderWidth = 1
        self.titleLbl.text = "noteshelf.ai.privacy.title".localized
        self.cancelBtn.setTitle("Cancel".localized, for: .normal)
        self.saveBtn.setTitle("SaveKey".localized, for: .normal)
        setUptickBtn(status:true)
        setUpParagraphText()
        setUpPrivacyPolicyText()
    }
    
    private func setUpParagraphText() {
        let text = "noteshelf.ai.privacy.description".localized
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        paragraphStyle.paragraphSpacing = 12
        paragraphStyle.alignment = .justified
        
        let attributedString = NSAttributedString(string: text, attributes: [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 17),
            .foregroundColor: UIColor.appColor(.black1)
        ])
        self.descriptionLbl.attributedText = attributedString
    }
    
    private func setUpPrivacyPolicyText() {
        let tapHereLocalized = "iap.privacy".localized
        let originalString = "noteshelf.ai.privacy.terms.acceptnace".localized
        let range = (originalString as NSString).range(of: "%@")
        let attributedString = NSMutableAttributedString(string: originalString)
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.appColor(.blueDodger),
            .font: UIFont.systemFont(ofSize: 17)
        ]
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.appColor(.black1),
            .font: UIFont.systemFont(ofSize: 17)
        ]
        attributedString.addAttributes(linkAttributes, range: range)
        attributedString.addAttributes(normalAttributes, range: NSRange(location: 0, length: originalString.count))
        attributedString.replaceCharacters(in: range, with: tapHereLocalized)
        attributedString.addAttributes(linkAttributes, range: NSRange(location: range.location, length: tapHereLocalized.count))
        privacyPolicy.attributedText = attributedString
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
        privacyPolicy.isUserInteractionEnabled = true
        privacyPolicy.addGestureRecognizer(tapGesture)
    }
    
    @objc func labelTapped(_ recognizer: UITapGestureRecognizer) {
        let text = (privacyPolicy.attributedText?.string ?? "") as NSString
        let privacyPolicyText = "iap.privacy".localized
        let clickableRange = text.range(of: privacyPolicyText)
        if recognizer.detectTappedTextIn(label: privacyPolicy, inRange: clickableRange) {
            if let privacyURL = URL(string: "https://www.noteshelf.net/privacy.html") {
                let safariController = SFSafariViewController(url: privacyURL);
                safariController.modalPresentationStyle = .fullScreen
                safariController.modalTransitionStyle = .coverVertical
                self.present(safariController, animated: true);
            }
        }
    }
    
    private func setUptickBtn(status: Bool) {
        let image : UIImage? = status ? nil : UIImage(named: "checkWhite")
        self.tickBtn.setImage(image, for: .normal)
        self.tickBtn.backgroundColor = status ? .clear : UIColor.appColor(.accent)
        self.tickBtn.layer.cornerRadius = 11
        self.tickBtn.layer.borderColor = status ? UIColor.appColor(.black20).cgColor : UIColor.clear.cgColor
        self.tickBtn.layer.borderWidth = status ? 1.5 : 0
        self.saveBtn.isEnabled =  status ? false : true
        if UIScreen.main.traitCollection.userInterfaceStyle == .dark {
            self.saveBtn.alpha = status ? 0.3 : 1
        } else {
            self.saveBtn.alpha = status ? 0.5 : 1
        }             }
}

extension UITapGestureRecognizer {
    func detectTappedTextIn(label: UILabel, inRange targetRange: NSRange) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(
            x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
            y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y
        )
        let locationOfTouchInTextContainer = CGPoint(
            x: locationOfTouchInLabel.x - textContainerOffset.x,
            y: locationOfTouchInLabel.y - textContainerOffset.y
        )
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        return NSLocationInRange(indexOfCharacter, targetRange)
    }

}
