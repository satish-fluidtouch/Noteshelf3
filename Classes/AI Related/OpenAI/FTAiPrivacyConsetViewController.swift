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
            .foregroundColor: UIColor.black
        ])
        self.descriptionLbl.attributedText = attributedString
    }
    
    private func setUpPrivacyPolicyText(){
        let text = "noteshelf.ai.privacy.terms.acceptnace".localized
        let privacyPolicyText = "iap.privacy".localized
        let title = String(format: text, privacyPolicyText)
        let attrbutedText = NSMutableAttributedString(string: title)
        let clickableRange = (title as NSString).range(of: privacyPolicyText)
        attrbutedText.addAttribute(.foregroundColor, value: UIColor.appColor(.blueDodger), range: clickableRange)
        privacyPolicy.attributedText = attrbutedText
        privacyPolicy.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
        privacyPolicy.addGestureRecognizer(tapGesture)
        
    }
    
    @objc func labelTapped(_ recognizer: UITapGestureRecognizer) {
        let text = (privacyPolicy.attributedText?.string ?? "") as NSString
        let privacyPolicyText = "iap.privacy".localized
        let clickableRange = text.range(of: privacyPolicyText)
        
        let tapLocation = recognizer.location(in: privacyPolicy)
        
        let textStorage = NSTextStorage(attributedString: privacyPolicy.attributedText!)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: privacyPolicy.bounds.size)
        textContainer.lineFragmentPadding = 0
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        let characterIndex = layoutManager.characterIndex(for: tapLocation, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        if NSLocationInRange(characterIndex, clickableRange) {
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
        self.saveBtn.alpha = status ? 0.5 : 1
    }
}
