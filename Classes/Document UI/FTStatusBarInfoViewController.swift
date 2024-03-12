//
//  FTStatusBarInfoViewController.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 11/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTStatusBarInfoViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var footerTextView: UITextView!
    @IBOutlet weak var statusBarLabel: UILabel!
    @IBOutlet weak var uiSwitch: UISwitch!
    @IBOutlet weak var toggleView: UIView!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override var shouldAvoidDismissOnSizeChange: Bool {
        return true
    }
    
    override func viewDidLoad() {
        titleLabel.text = "status_bar_info_title".localized
        subtitleLabel.text = "status_bar_info_subtitle".localized
        statusBarLabel.text = "show_status_bar".localized
        constructFooterText()
        toggleView.layer.cornerRadius = 10
        subtitleLabel.addLineSpacing(5)
        uiSwitch.isOn = FTUserDefaults.defaults().showStatusBar
        footerTextView.delegate = self
        footerTextView.textAlignment = .center
        self.isModalInPresentation = true
    }
    
    private func constructFooterText() {
        let tapHereLocalized = "status_bar_tap_here".localized
        let originalString = "status_bar_info_footer".localized
        if let range = originalString.range(of: "%@") {
            let attributedString = NSMutableAttributedString(string: originalString)
            let linkAttributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.link: appStoreLink(),
                .foregroundColor: UIColor.appColor(.accent),
                .strokeColor: UIColor.appColor(.accent),
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .font: UIFont.appFont(for: .bold, with: 13)
            ]
            let normalAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.appColor(.black50),
                .font: UIFont.appFont(for: .bold, with: 13)
            ]
            attributedString.addAttributes(linkAttributes, range: NSRange(range, in: originalString))
            attributedString.addAttributes(normalAttributes, range: NSRange(location: 0, length: originalString.count))
            let nsRange = NSRange(range,in: originalString);
            attributedString.replaceCharacters(in: nsRange, with: tapHereLocalized)
            footerTextView.attributedText = attributedString
        }
    }
    
    private func appStoreLink() -> URL {
        #if ENTERPRISE_EDITION
        return URL(string: "https://itunes.apple.com/us/app/noteshelf-3/id6471592545?mt=8")!
        #else
        return URL(string: "https://itunes.apple.com/us/app/noteshelf-3/id6458735203?mt=8")!
        #endif
    }
    
    static func present(on parentController: UIViewController)  {
        let storyBoard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        if let controller: FTStatusBarInfoViewController = storyBoard.instantiateViewController(withIdentifier: "FTStatusBarInfoViewController") as? FTStatusBarInfoViewController {
            parentController.ftPresentFormsheet(vcToPresent: controller, contentSize: CGSize(width: 700, height: 740))
        } else {
            fatalError("FTStatusBarInfoViewController doesnt exist")
        }
    }
    
    @IBAction func onSwitchChanged(_ sender: UISwitch) {
        FTUserDefaults.defaults().showStatusBar = sender.isOn
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
}

extension UILabel {
    func addLineSpacing(_ lineSpacing: CGFloat) {
        guard let labelText = self.text else { return }
        let attributedString = NSMutableAttributedString(string: labelText)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.alignment = self.textAlignment
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))
        self.attributedText = attributedString
    }
}
