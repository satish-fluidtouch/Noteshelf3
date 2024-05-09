//
//  FTCustomToolbarFooterView.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 15/04/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

protocol FTCustomToolbarFooterViewProtocal:AnyObject {
    func navigateToContactUsPage()
}

class FTCustomToolbarFooterView : UIView {
    
    @IBOutlet weak private var topBtn: UIButton!
    @IBOutlet weak private var bgVIew: UIView!
    @IBOutlet weak private var iconsBgView: UIView!
    @IBOutlet weak var ideaForShortcutLbl: UILabel!
    @IBOutlet weak var requestLbl: UILabel!
    
    @IBOutlet weak var stackView: UIStackView!
    weak var delegate : FTCustomToolbarFooterViewProtocal?
    
    
    func getHeight() -> CGFloat {
        let size1 = ideaForShortcutLbl.sizeThatFits(CGSize(width: stackView.frame.width, height: 0)).width
        let size2 = requestLbl.sizeThatFits(CGSize(width: stackView.frame.width, height: 0)).width

        let height1 = ideaForShortcutLbl.text?.getHeight(using: .systemFont(ofSize: 13), width: size1) ?? 20
        let height2 = requestLbl.text?.getHeight(using: .systemFont(ofSize: 12), width: size2) ?? 20
        return height1 + height2 + CGFloat(26)
    }
    
    func setUpUi() {
        ideaForShortcutLbl.text = "customizeToolbar.ideaForShortcut".localized
        requestLbl.text = "customizeToolbar.requestForShortcut".localized
        self.iconsBgView?.addShadow(CGSize(width: 0, height: 10), color: UIColor.appColor(.black10), opacity:1, radius: 30)
        addUnderline()
        addGesture()
    }
    
    func addUnderline() {
        if let textString = self.requestLbl.text {
               let attributedString = NSMutableAttributedString(string: textString)
               attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: attributedString.length))
            requestLbl.attributedText = attributedString
           }
       }
    
    func addGesture() {
        let tap = UITapGestureRecognizer(target:self, action: #selector(self.tappedOnBgView))
        self.bgVIew.isUserInteractionEnabled = true
        self.bgVIew.addGestureRecognizer(tap)
    }
    
    @objc func tappedOnBgView() {
        self.delegate?.navigateToContactUsPage()
    }
    
}
