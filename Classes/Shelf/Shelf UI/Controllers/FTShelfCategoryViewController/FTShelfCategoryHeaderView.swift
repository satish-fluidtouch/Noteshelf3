//
//  FTShelfCategoryHeaderView.swift
//  Noteshelf
//
//  Created by Amar on 16/12/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

protocol FTShelfCategoryHeaderViewDelegate : AnyObject {
    func headerView(_ view : FTShelfCategoryHeaderView,category : FTShelfCategoryCollection,didCollapsed  collapsed : Bool);
    func headerView(_ view : FTShelfCategoryHeaderView?, didTapOnAddNewCategory : FTShelfCategoryCollection?);
}

class FTShelfCategoryHeaderView: UITableViewHeaderFooterView {
    @IBOutlet private weak var titleLabel : UILabel?
    @IBOutlet private weak var hoverAddActionButton : UIButton?
    @IBOutlet private weak var hoverToggleActionButton : UIButton?
    @IBOutlet private weak var hoverContentView : UIView?

    private weak var shelfCategory : FTShelfCategoryCollection?
    
    weak var headerDelegate : FTShelfCategoryHeaderViewDelegate?;
    
    override func awakeFromNib() {
        super.awakeFromNib();
    }
    
    @IBAction private func didTapOnHoverAddAction(_ sender : UIButton)
    {
        if let category = self.shelfCategory {
            self.headerDelegate?.headerView(self, didTapOnAddNewCategory: category);
        }
    }
    
    @IBAction private func didTapOnHoverToggleAction(_ sender : UIButton)
    {
        if let category = self.shelfCategory {
            category.isCollapsed = !category.isCollapsed;
            self.headerDelegate?.headerView(self, category: category, didCollapsed: category.isCollapsed);
        }
    }

    func configUI(_ category : FTShelfCategoryCollection)
    {
        self.shelfCategory = category;
        
        self.hoverAddActionButton?.alpha = 0.0;
        self.hoverToggleActionButton?.alpha = 0.0;

        let mulFact : CGFloat = 1.0;//1.3;
        
        var attrs : [NSAttributedString.Key : Any] =  [NSAttributedString.Key : Any]();
        attrs[.font] = UIFont.appFont(for: .bold, with: 14 * mulFact)
        attrs[.foregroundColor] = UIColor.headerColor.withAlphaComponent(0.76);
        attrs[.kern] = NSNumber(value: Float(0.07 * mulFact));
        self.titleLabel?.attributedText = NSAttributedString.init(string: category.title,
                                                                  attributes: attrs);
        
        var hoverTitleString = NSLocalizedString("Show", comment: "Show")
        if !category.isCollapsed {
            hoverTitleString = "  " + NSLocalizedString("Hide", comment: "Hide")
        }
        attrs[.foregroundColor] = UIColor.headerColor.withAlphaComponent(0.5);
        self.hoverToggleActionButton?.setAttributedTitle(NSAttributedString.init(string: hoverTitleString,
                                                                                 attributes: attrs), for: .normal);
    }
    
    func hovering(point : CGPoint?) //point to be in window level
    {
        var showOptions = false;
        if let inPoint = point {
            let location = self.convert(inPoint, from: nil);
            showOptions = self.bounds.contains(location);
        }
        if(showOptions) {
            self.hoverAddActionButton?.alpha = 0;
            if let category = self.shelfCategory,
                category.canAdd,
                !category.isCollapsed {
                self.hoverAddActionButton?.alpha = 1;
            }
            self.hoverToggleActionButton?.alpha = 1.0;
        }
        else {
            self.hoverAddActionButton?.alpha = 0.0;
            self.hoverToggleActionButton?.alpha = 0.0;
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse();
        self.titleLabel?.attributedText = NSAttributedString.init(string: "");
        self.hoverToggleActionButton?.alpha = 0.0;
        self.hoverAddActionButton?.alpha = 0.0;
    }
}
