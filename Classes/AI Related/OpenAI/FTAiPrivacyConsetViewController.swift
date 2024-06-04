//
//  FTAiPrivacyConsetViewController.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 03/06/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SafariServices
protocol FTAiPrivacyConsetViewControllerProtocal {
    func showAiScreen()
}

class FTAiPrivacyConsetViewController: UIViewController {

    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var tickBtn: UIButton!
    @IBOutlet weak var privacyPolicy: UILabel!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
     var delegate : FTAiPrivacyConsetViewControllerProtocal?
    
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
       UserDefaults.standard.set(true, forKey: "isAiPrivacyPolicyAccepted")
       self.dismiss(animated:false)
       self.delegate?.showAiScreen()
    }
    
    func setUpUi() {
        self.bgView?.addShadow(CGSize(width: 0, height: 0), color: UIColor.appColor(.black20), opacity: 0.24 ,radius: 8.0)
        self.bgView.layer.cornerRadius = 16
        self.cancelBtn.layer.borderColor  = UIColor.appColor(.accent).cgColor
        self.cancelBtn.layer.borderWidth = 1
        setUptickBtn(status:true)
        setUpParagraphText()
        setUpPrivacyPolicyText()
       
    }
    
    func setUpParagraphText() {
        let text = """
To invoke any of the Noteshelf AI functions, we need to send the contents of the current page to our AI partner’s server for processing.
Please rest assured that we respect your privacy and will not use this data for anything else. You can learn more about how we handle your data in our Privacy Policy.
"""
        
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
    
    func setUpPrivacyPolicyText(){
        let text = "I have read and agree with the Privacy Policy."
        let attrbutedText = NSMutableAttributedString(string:text)
        let clickableRange = (text as NSString).range(of: "Privacy Policy.")
        attrbutedText.addAttribute(.foregroundColor, value: UIColor.init(hexString: "0455CF"), range: clickableRange)
        privacyPolicy.attributedText = attrbutedText
        privacyPolicy.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
        privacyPolicy.addGestureRecognizer(tapGesture)
        
    }
    
    @objc func labelTapped(_ recognizer: UITapGestureRecognizer) {
        guard let label = recognizer.view as? UILabel else { return }
        let text = (label.attributedText?.string ?? "") as NSString
        
        let clickableRange = text.range(of: "Privacy Policy.")
        
        let tapLocation = recognizer.location(in: label)
        
        let textStorage = NSTextStorage(attributedString: label.attributedText!)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)
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
    
    func setUptickBtn(status: Bool) {
        if status {
            self.tickBtn.setImage(nil, for: .normal)
            self.tickBtn.backgroundColor = .clear
            self.tickBtn.layer.cornerRadius = 11
            self.tickBtn.layer.borderColor  = UIColor.appColor(.black20).cgColor
            self.tickBtn.layer.borderWidth = 1.5
            self.saveBtn.isEnabled = false
            self.saveBtn.alpha = 0.5
        }else {
            let image = UIImage(named: "checkWhite")
            self.tickBtn.setImage(image, for: .normal)
            self.tickBtn.backgroundColor = UIColor.appColor(.accent)
            self.tickBtn.layer.cornerRadius = 11
            self.tickBtn.layer.borderColor  = UIColor.clear.cgColor
            self.tickBtn.layer.borderWidth = 0
            self.saveBtn.isEnabled = true
            self.saveBtn.alpha = 1
        }
    }
}
