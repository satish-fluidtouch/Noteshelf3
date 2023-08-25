//
//  FTNoteshelfAITextViewViewController.swift
//  Sample AI
//
//  Created by Amar Udupa on 28/07/23.
//

import UIKit
import OpenAI
import Foundation

protocol FTNoteshelfAITextViewViewControllerDelegate:NSObjectProtocol {
    func textViewController(_ controller: FTNoteshelfAITextViewViewController, didSelectOption action: FTNotesehlfAIAction,content: String);
}
enum FTNotesehlfAIAction: Int {
    case copyToClipboard,addToPage,addToNewPage,regenerateResponse,addHandwriting,addNewPageHandwriting;
    
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
        }
    }
}

class FTNotesehlfAIButton: UIButton {
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
            self.layer.borderWidth = 2;
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
    @IBOutlet private weak var stackView: UIStackView?;
    @IBOutlet private weak var moreButton: UIButton?;
    @IBOutlet private weak var clipboardButton: FTNotesehlfAIButton?;
    @IBOutlet private weak var addAsHandwrite: FTNotesehlfAIButton?;
    @IBOutlet private weak var addToPageButton: FTNotesehlfAIButton?;

    weak var delegate: FTNoteshelfAITextViewViewControllerDelegate?;
    var supportsHandwriting = false {
        didSet {
            self.updateButtonStates();
        }
    }
    
    @IBOutlet private weak var stackHeightConstraint: NSLayoutConstraint?;
        
    func insertText(_ text:String) {
        if let txtView = self.textView {
            let position = txtView.selectedRange.location;
            txtView.insertText(text);
            txtView.scrollRangeToVisible(NSRange(location: position+text.count, length: 0));
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView?.layer.cornerRadius = 10.0
        self.supportsHandwriting = !UIDevice.isChinaRegion;
        let menuItem = UIDeferredMenuElement.uncached { items in
            var menuItems = [UIMenuElement]();
            var menuActions: [FTNotesehlfAIAction] =  [.regenerateResponse];
            
            if self.clipboardButton?.isHidden ?? false {
                menuActions.append(.copyToClipboard);
            }

            if self.addToPageButton?.isHidden ?? false {
                menuActions.append(.addToPage);
            }
            menuActions.append(.addToNewPage);

            if(self.supportsHandwriting) {
                menuActions.append(.addNewPageHandwriting);
            }

            menuActions.forEach { eachItem in
                let menuItem = UIAction(title: eachItem.displayTitle(self.supportsHandwriting)) { [weak self] _ in
                    if let strongSelf = self {
                        strongSelf.delegate?.textViewController(strongSelf
                                                                , didSelectOption: eachItem
                                                                ,content: self?.textView?.text ?? "");
                    }
                }
                menuItems.append(menuItem);
            }
            items(menuItems)
        }
        
        self.moreButton?.menu = UIMenu(children: [menuItem]);
        self.moreButton?.showsMenuAsPrimaryAction = true;
        self.updateButtonStates();
    }
         
    private func updateButtonStates() {
        self.addAsHandwrite?.isHidden = !self.supportsHandwriting;
        self.clipboardButton?.isHidden = self.supportsHandwriting
        if self.view.frame.width < 400 {
            self.clipboardButton?.isHidden = true;
            self.addToPageButton?.isHidden = self.supportsHandwriting;
        }
        self.clipboardButton?.setTitle(FTNotesehlfAIAction.copyToClipboard.displayTitle(self.supportsHandwriting), for: .normal);
        self.addToPageButton?.setTitle(FTNotesehlfAIAction.addToPage.displayTitle(self.supportsHandwriting), for: .normal);
        self.addAsHandwrite?.setTitle(FTNotesehlfAIAction.addHandwriting.displayTitle(self.supportsHandwriting), for: .normal);
        if let button = self.clipboardButton, !button.isHidden {
            button.hasBorder = true;
        }
        if let button = self.addAsHandwrite {
            self.addToPageButton?.hasBorder = !button.isHidden
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        self.clipboardButton?.isHidden = (self.view.frame.size.width < 400)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self](_) in
            self?.updateButtonStates();
        }, completion: { (_) in
            
        })
    }
    
    @IBAction func copyToClipboard(_ sender:Any) {
        self.delegate?.textViewController(self
                                          , didSelectOption: .copyToClipboard
                                          ,content: self.textView?.text ?? "");
    }

    @IBAction func addToPage(_ sender:Any) {
        self.delegate?.textViewController(self
                                          , didSelectOption: .addToPage
                                          ,content: self.textView?.text ?? "");
    }

    @IBAction func addAsHandwrite(_ sender:Any?) {
        self.delegate?.textViewController(self
                                          , didSelectOption: .addHandwriting
                                          ,content: self.textView?.text ?? "");
    }

    @IBAction func moreOptions(_ sender:Any) {
        
    }
    
    func showPlaceHolder(_ string: String) {
        self.textView?.text = string;
    }
    
    func showActionOptions(_ show: Bool) {
        let heightConstraint: CGFloat = show ? 44 : 0;
        self.stackHeightConstraint?.constant = heightConstraint;
//        if self.stackHeightConstraint?.constant != heightConstraint {
//            UIView.animate(withDuration: 0.3) {
//                self.stackHeightConstraint?.constant = heightConstraint;
//                self.view.layoutIfNeeded();
//            }
//        }
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
