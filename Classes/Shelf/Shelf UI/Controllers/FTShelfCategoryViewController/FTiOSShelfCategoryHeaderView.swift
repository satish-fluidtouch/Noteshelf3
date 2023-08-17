//
//  FTiOSShelfCategoryHeaderView.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 27/01/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

protocol FTiOSShelfCategoryHeaderViewDelegate : AnyObject {
    func headerView(_ view: FTiOSShelfCategoryHeaderView,category : FTShelfCategoryCollection, didCollapsed collapsed: Bool);
}

class FTiOSShelfCategoryHeaderView: UITableViewHeaderFooterView {
    @IBOutlet private weak var titleLabel : FTCustomLabel?
    @IBOutlet private weak var hoverToggleActionButton : UIButton?
    @IBOutlet private weak var hoverContentView : UIView?
    @IBOutlet private weak var arrowImageView : UIImageView?

    private weak var shelfCategory : FTShelfCategoryCollection?;
    
    weak var headerDelegate : FTiOSShelfCategoryHeaderViewDelegate?;
    private var isAnimating: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib();
    }
    deinit{
        #if DEBUG
        print("FTiOSShelfCategoryHeaderView deinit")
        #endif
    }
    @IBAction private func didTapOnHoverToggleAction(_ sender : UIButton)
    {
        if self.isAnimating {
            return
        }
        
        if let category = self.shelfCategory {
            category.isCollapsed = !category.isCollapsed;
            
            self.isAnimating = true
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.arrowImageView?.transform = category.isCollapsed ? CGAffineTransform(rotationAngle: -.pi/2.0) : CGAffineTransform.identity
            }) { [weak self] (_) in
                self?.isAnimating = false
            }
            runInMainThread(0.1) {[weak self] in
                guard let `self` = self else {
                    return
                }
                self.headerDelegate?.headerView(self, category: category, didCollapsed: category.isCollapsed);
            }
        }
    }

    func configUI(_ category : FTShelfCategoryCollection)
    {
        self.shelfCategory = category;
        self.titleLabel?.text = category.title
//        self.titleLabel?.textColor = .categoryTitleColor
        self.titleLabel?.font = UIFont.clearFaceFont(for: .medium, with: 22)
        if !self.isAnimating {
            self.arrowImageView?.transform = category.isCollapsed ? CGAffineTransform(rotationAngle: -.pi/2.0) : CGAffineTransform.identity
        }
        if category.type == .systemDefault {
            hoverToggleActionButton?.isHidden = true
            arrowImageView?.isHidden = true
        }
    }
        
    override func prepareForReuse() {
        super.prepareForReuse();
//        self.titleLabel?.attributedText = NSAttributedString.init(string: "");
        self.hoverToggleActionButton?.isSelected = false
    }
}
