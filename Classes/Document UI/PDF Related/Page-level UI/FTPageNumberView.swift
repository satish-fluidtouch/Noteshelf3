//
//  FTPageNumberView.swift
//  Noteshelf
//
//  Created by Ramakrishna on 09/05/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTStyles

@objcMembers class FTPageNumberView : UIView {
    
    fileprivate weak var pageNumberInfoLabel : UILabel?
    fileprivate var page : FTPageProtocol?
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    convenience init(frame: CGRect, page : FTPageProtocol) {
        self.init()
        self.isUserInteractionEnabled = false;
        let pageLabel = UILabel.init(frame: frame);
        pageLabel.textAlignment = NSTextAlignment.center;
        pageLabel.backgroundColor = UIColor.init(hexString: "#111111",alpha: 0.1)
        pageLabel.font = UIFont.appFont(for: .medium, with: 15)
        pageLabel.layer.cornerRadius = 6.0
        pageLabel.layer.masksToBounds = true
        self.addSubview(pageLabel);
        self.pageNumberInfoLabel = pageLabel;
        self.pageNumberInfoLabel?.textColor = UIColor.appColor(.readOnlyModePageNumberTint);
        self.page = page
        self.setCurrentPage(page)
        self.updateTextColor();
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCurrentPage(_ page : FTPageProtocol) {
        self.updateTextColor();
        if let document = page.parentDocument {
            let attributedPageNumberInfo = NSAttributedString(string: String.init(format: NSLocalizedString("NofNAlt", comment: "%d of %d"),page.pageIndex()+1,document.pages().count))
            let pageNumberInfo = attributedPageNumberInfo.string
            self.pageNumberInfoLabel?.frame = CGRect(x: 8, y: 70.5, width: (attributedPageNumberInfo.size().width + 16), height: 24)
            self.pageNumberInfoLabel?.text =  pageNumberInfo
        }
        else {
            self.pageNumberInfoLabel?.text = "";
        }
    }
    
    private func updateTextColor()
    {
        guard ((page?.templateInfo.isTemplate) != nil) ,
            let _page = page as? FTPageBackgroundColorProtocol
            else {
                return;
        }
        _page.pageBackgroundColor { (color) in
            self.pageNumberInfoLabel?.textColor = UIColor.appColor(.black70);
        }
    }
}
