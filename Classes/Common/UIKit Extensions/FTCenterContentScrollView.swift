//
//  FTCenterContentScrollView.swift
//  Noteshelf
//
//  Created by Amar on 24/03/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objcMembers class FTCenterContentScrollView: UIScrollView {

    weak var contentHolderView: UIView?;
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        self.initialize()
    }
    
    private func initialize()
    {
        let contentView = UIView.init(frame: self.bounds);
        contentView.clipsToBounds = true;
        contentInsetAdjustmentBehavior = .never;
        self.addSubview(contentView);
        self.contentHolderView = contentView;
    }
    
    override func layoutSubviews() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performLayout), object: nil);
        if(self.applicationState() == .background) {
            self.perform(#selector(performLayout), with: nil, afterDelay: 0.01)
        }
        else {
            self.performLayout();
        }
    }
    
    @objc private func performLayout() {
        guard let contentView = self.contentHolderView else {
            return;
        }
        if(self.isZooming && self.zoomScale <= self.minimumZoomScale) {
            return;
        }
        self.centerContentHolderView(contentView);
    }
    
    func forceLayoutSubviews() {
        self.performLayout();
    }
}
