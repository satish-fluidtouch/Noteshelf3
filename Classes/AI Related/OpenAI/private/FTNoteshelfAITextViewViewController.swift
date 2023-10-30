//
//  FTNoteshelfAITextViewViewController.swift
//  Sample AI
//
//  Created by Amar Udupa on 28/07/23.
//

import UIKit
import OpenAI
import Foundation

class FTAIContent {
    private(set) var attributedString: NSAttributedString?;
    required init(with attrString: NSAttributedString?) {
        attributedString = attrString;
    }
    
    var normalizedAttrText: NSAttributedString? {
        if let attr = attributedString?.mapAttributesToMatch(withLineHeight: -1) {
            let mutableAttr = NSMutableAttributedString(attributedString: attr);
            mutableAttr.beginEditing();
            mutableAttr.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: attr.length), options: .reverse) { value, _range, _stop in
                if let style = value as? NSParagraphStyle,style.hasBullet() {
                    let nsString = (mutableAttr.string as NSString);
                    var lineRange = nsString.lineRange(for: NSRange(location: NSMaxRange(_range), length: 0));
                    while lineRange.location != NSNotFound,
                          lineRange.location >= _range.location {
                        let str = mutableAttr.attributedSubstring(from: lineRange);
                        if str.string.hasPrefix("\t") {
                            mutableAttr.deleteCharacters(in: NSRange(location: lineRange.location, length: 1));
                        }
                        let prevlocation = lineRange.location - 1;
                        if prevlocation < 0 {
                            lineRange = NSRange(location: NSNotFound, length: 0);
                        }
                        else {
                            lineRange = nsString.lineRange(for: NSRange(location: prevlocation, length: 0));
                        }
                    }
                }
            }
            mutableAttr.endEditing();
            return mutableAttr;
        }
        return nil;
    }
}

protocol FTNoteshelfAITextViewViewControllerDelegate:NSObjectProtocol {
    func textViewController(_ controller: FTNoteshelfAITextViewViewController, didSelectOption action: FTNotesehlfAIAction,content: FTAIContent);
}

enum FTNotesehlfAIAction: Int {
    case copyToClipboard,addToPage,addToNewPage,regenerateResponse,addHandwriting,addNewPageHandwriting,semdFeedback;
    
    func displayTitle(_ supportsHandwrite: Bool) -> String {
        switch self {
        case .addHandwriting:
            return "noteshelf.ai.actionAddHandwriting".aiLocalizedString
        case .addNewPageHandwriting:
            return "noteshelf.ai.actionAddHandwritingNewPage".aiLocalizedString
        case .addToNewPage:
            if supportsHandwrite {
                return "noteshelf.ai.actionAddAsTextNewPage".aiLocalizedString
            }
            return "noteshelf.ai.actionAddToNewPage".aiLocalizedString
        case .addToPage:
            if supportsHandwrite {
                return "noteshelf.ai.actionAddAsText".aiLocalizedString
            }
            return "noteshelf.ai.actionAddToPage".aiLocalizedString
        case .copyToClipboard:
            return "noteshelf.ai.actionCopyToClipboard".aiLocalizedString
        case .regenerateResponse:
            return "noteshelf.ai.actionRegenerateResponse".aiLocalizedString
        case .semdFeedback:
            return "noteshelf.ai.sendFeedback".aiLocalizedString
        }
    }
}

class FTNoteshelfAIButton: UIButton {
    @IBInspectable var hasBorder: Bool = false {
        didSet {
            if hasBorder != oldValue {
                commoninit();
            }
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder);
        commoninit();
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        commoninit();
    }
    
    override func awakeFromNib() {
        super.awakeFromNib();
        commoninit();
    }
    
    private func commoninit() {
        if self.hasBorder {
            self.configuration?.baseForegroundColor = UIColor.appColor(.accent);
            self.layer.borderColor = UIColor.appColor(.accent).cgColor;
            self.layer.borderWidth = 1;
            self.backgroundColor = UIColor.clear;
        }
        else {
            self.configuration?.baseForegroundColor = UIColor.systemBackground
            self.layer.borderWidth = 0;
            self.backgroundColor = UIColor.appColor(.accent)
        }
        self.layer.cornerRadius = 10;
    }
}

class FTNoteshelfAITextViewViewController: UIViewController {
    @IBOutlet private weak var textView: UITextView?;
    @IBOutlet private weak var primaryActionButton: FTNoteshelfAIButton?;
    @IBOutlet private weak var secondaryActionButton: FTNoteshelfAIButton?;
    @IBOutlet private weak var moreOptionsButton: FTNoteshelfAIButton?;

    weak var delegate: FTNoteshelfAITextViewViewControllerDelegate?;
    var supportsHandwriting = false {
        didSet {
            self.updateButtonStates();
        }
    }
    
    @IBOutlet private weak var footerActionBottomConstraint: NSLayoutConstraint?;
        
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = self.textView?.layoutManager;
        self.textView?.layer.cornerRadius = 10.0
        self.supportsHandwriting = !UIDevice.isChinaRegion;
        let menuItem = UIDeferredMenuElement.uncached { items in
            var menuItems = [UIMenuElement]();
            var menuActions: [FTNotesehlfAIAction] =  [.semdFeedback,.regenerateResponse];
            
            if self.supportsHandwriting {
                menuActions.append(.copyToClipboard);
                menuActions.append(.addToNewPage);
                menuActions.append(.addNewPageHandwriting);
            }
            else {
                menuActions.append(.addToNewPage);
            }
            
            menuActions.forEach { eachItem in
                let menuItem = UIAction(title: eachItem.displayTitle(self.supportsHandwriting)) { [weak self] _ in
                    if let strongSelf = self {
                        let content = FTAIContent(with: self?.textView?.attributedText);
                        strongSelf.delegate?.textViewController(strongSelf
                                                                , didSelectOption: eachItem
                                                                ,content: content);
                    }
                }
                menuItems.append(menuItem);
            }
            items(menuItems)
        }
        
        self.primaryActionButton?.addTarget(self, action: #selector(self.primaryButtonPressAction(_:)), for: .touchUpInside);
        self.secondaryActionButton?.addTarget(self, action: #selector(self.secondaryButtonPressAction(_:)), for: .touchUpInside);
        
        self.moreOptionsButton?.menu = UIMenu(children: [menuItem]);
        self.moreOptionsButton?.showsMenuAsPrimaryAction = true;
        self.updateButtonStates();
    }
         
    deinit {
//        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.scrollToBottom), object: nil);
    }
    
    private func updateButtonStates() {
        let primaryAttributes: [NSAttributedString.Key : Any] = [
            .foregroundColor : UIColor.white
            , .font : UIFont.appFont(for: .medium, with: 15)];

        let secondaryAttributes: [NSAttributedString.Key : Any] = [
            .foregroundColor : UIColor.appColor(.accent)
            , .font : UIFont.appFont(for: .medium, with: 15)];

        var primaryTitle = FTNotesehlfAIAction.addToPage.displayTitle(self.supportsHandwriting);
        var secondaryTitle = FTNotesehlfAIAction.copyToClipboard.displayTitle(self.supportsHandwriting);
        
        if self.supportsHandwriting {
            primaryTitle = FTNotesehlfAIAction.addHandwriting.displayTitle(self.supportsHandwriting);
            secondaryTitle = FTNotesehlfAIAction.addToPage.displayTitle(self.supportsHandwriting);
        }
        let primaryAttrTitle = NSAttributedString(string: primaryTitle,attributes: primaryAttributes);
        let secondaryAttrTitle = NSAttributedString(string: secondaryTitle,attributes: secondaryAttributes);
        
        self.primaryActionButton?.setAttributedTitle(primaryAttrTitle, for: .normal);
        self.secondaryActionButton?.setAttributedTitle(secondaryAttrTitle, for: .normal);
        
        let moreOptionAttr = NSAttributedString(string: "noteshelf.ai.credit.moreOptions".aiLocalizedString, attributes: secondaryAttributes);
        self.moreOptionsButton?.setAttributedTitle(moreOptionAttr, for: .normal);
    }
        
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self](_) in
            self?.updateButtonStates();
        }, completion: { (_) in
            
        })
    }
    
    @objc private func primaryButtonPressAction(_ sender: Any?) {
        let content = FTAIContent(with: self.textView?.attributedText);
        if supportsHandwriting {
            self.delegate?.textViewController(self
                                              , didSelectOption: .addHandwriting
                                              ,content: content);
        }
        else {
            self.delegate?.textViewController(self
                                              , didSelectOption: .addToPage
                                              ,content: content);
        }
    }

    @objc private func secondaryButtonPressAction(_ sender: Any?) {
        let content = FTAIContent(with: self.textView?.attributedText);
        if supportsHandwriting {
            self.delegate?.textViewController(self
                                              , didSelectOption: .addToPage
                                              ,content: content);
        }
        else {
            self.delegate?.textViewController(self
                                              , didSelectOption: .copyToClipboard
                                              ,content: content);
        }
    }

    func showPlaceHolder(_ string: String) {
        self.textView?.text = string;
    }
    
    func showActionOptions(_ show: Bool) {
        let heightConstraint: CGFloat = show ? 0 : 112;
        self.footerActionBottomConstraint?.constant = heightConstraint;
    }
    
//    @objc private func scrollToBottom() {
//        if let txtView = self.textView {
//            txtView.scrollRangeToVisible(NSRange(location: max(txtView.attributedText.length-1,0), length: 0));
//        }
//    }
    
    func showResponse(_ response: FTOpenAIResponse) {
        let attrString = response.attributedString();
        if let txtView = self.textView, txtView.attributedText.string != attrString.string {
            txtView.textStorage.beginEditing();
            txtView.textStorage.setAttributedString(attrString);
            txtView.textStorage.endEditing();
//            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.scrollToBottom), object: nil);
//            self.perform(#selector(self.scrollToBottom), with: nil, afterDelay: 0.2);
            txtView.scrollRangeToVisible(NSRange(location: max(txtView.attributedText.length-1,0), length: 0));
        }
    }
}

extension UIDevice {
    static var isChinaRegion: Bool {
        if let  countryCode = (NSLocale.current as NSLocale).countryCode,
           countryCode.lowercased() == "cn" {
            return true;
        }
        return false;
    }
    
    static var supportedLanguages: Bool {
        let supportedLanguages = ["en","de","it","fr","es"];
        if let languahe = Locale.current.language.languageCode?.identifier {
            if supportedLanguages.first(where: {$0.hasPrefix(languahe)}) != nil {
                return true;
            }
        }
        return false;
    }
}
