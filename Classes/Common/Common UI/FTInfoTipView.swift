//
//  FTInfoTipView.swift
//  Noteshelf
//
//  Created by Narayana on 07/01/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

protocol FTInfoTipDelegate: AnyObject {
    func didClickOnButton(ofType actionType: FTInfoTipButtonType)
}

enum FTInfoTipButtonType {
    case keepHorizantal
    case showVertical
    case close
    case changeTemplate
}

enum FTInfoTipShowView {
    case verticalScroll
    case morePaperTemplates
}

class FTInfoTipView: UIView {

    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var lblTitle: UILabel?
    @IBOutlet weak var lblSubTitle: UILabel?
    @IBOutlet weak var firstBtn: UIButton?
    @IBOutlet weak var secondBtn: UIButton?
    @IBOutlet weak var tipIconImageView: UIImageView!
    
    @IBOutlet weak var stackView: UIStackView?
    @IBOutlet weak var stackViewTrailingConstraint: NSLayoutConstraint?

    weak var infoTipDelegate: FTInfoTipDelegate?
    
    var infoTipShowView: FTInfoTipShowView?
    
    override private init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        Bundle.main.loadNibNamed("FTInfoTipView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func configureTextAndTipImage(titleStr: String, subTitleStr: String, firstBtnStr: String, secondBtnStr: String, imageName: String) {
        self.lblTitle?.text = titleStr
        self.lblSubTitle?.text = subTitleStr
        self.firstBtn?.setTitle(firstBtnStr, for: UIControl.State.normal)
        self.secondBtn?.setTitle(secondBtnStr, for: UIControl.State.normal)
        self.tipIconImageView.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
    }
    
    func configureUI(with infoTipShowView: FTInfoTipShowView) {
        self.infoTipShowView = infoTipShowView
        self.firstBtn?.layer.cornerRadius = 7.0
        self.firstBtn?.layer.borderWidth = 1.0
        self.firstBtn?.layer.borderColor = UIColor.white.cgColor
        
        self.secondBtn?.layer.cornerRadius = 7.0
        if FTUtils.currentLanguage() != "en" || UIDevice.current.isIphone() {
            stackView?.axis = .vertical
            stackView?.spacing = 8
            stackViewTrailingConstraint?.constant = 30
        }
        else {
            stackView?.axis = .horizontal
            stackView?.spacing = 6
            stackViewTrailingConstraint?.constant = 16
        }
        self.layoutIfNeeded()
    }
    
    @IBAction func firstBtnTapped(_ sender: Any) {
        if self.infoTipShowView == .verticalScroll {
            self.infoTipDelegate?.didClickOnButton(ofType: .keepHorizantal)
        } else if self.infoTipShowView == .morePaperTemplates {
            self.infoTipDelegate?.didClickOnButton(ofType: .close)
        }
    }
    
    @IBAction func secondBtnTapped(_ sender: Any) {
        if self.infoTipShowView == .verticalScroll {
            self.infoTipDelegate?.didClickOnButton(ofType: .showVertical)
        } else if self.infoTipShowView == .morePaperTemplates {
            self.infoTipDelegate?.didClickOnButton(ofType: .changeTemplate)
        }
    }
    
}
