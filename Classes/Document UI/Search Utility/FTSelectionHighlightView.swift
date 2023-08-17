//
//  FTSelectionHighlightView.swift
//  Noteshelf
//
//  Created by Amar on 15/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

fileprivate class FTSelectionView : UIView {
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.isUserInteractionEnabled = false;
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.isUserInteractionEnabled = false;
    }
}

class FTSelectionHighlightView: UIView {

    override var layer: CALayer {
        let layer = super.layer;
        layer.compositingFilter = "multiplyBlendMode";
        return layer;
    }

    override var isUserInteractionEnabled: Bool {
        get {
            return false;
        }
        set {
            super.isUserInteractionEnabled = false;
        }
    }

    @objc func renderSearchItems(items : [FTSearchableItem]?,pdfScale : CGFloat,annotationScale : CGFloat) {
        self.subviews.forEach { (subview) in
            subview.removeFromSuperview();
        }
        
        if(nil != items) {
            items!.forEach { (eachItem) in
                switch(eachItem.searchType) {
                case .pdfText:
                    let view = FTSelectionView.init(frame: CGRectScale(eachItem.selectionRect, pdfScale).integral);
                    view.backgroundColor = UIColor.yellow;
                    self.addSubview(view);
                case .annotation:
                    let view = FTSelectionView.init(frame: CGRectScale(eachItem.selectionRect, annotationScale).integral);
                    view.backgroundColor = UIColor.yellow;
                    self.addSubview(view);
                case .handWritten:
                    let view = FTSelectionView.init(frame: CGRectScale(eachItem.selectionRect, annotationScale).integral);
                    view.backgroundColor = UIColor.yellow;
                    self.addSubview(view);
                    
                default:
                    break;
                }
            }
        }
    }
}
