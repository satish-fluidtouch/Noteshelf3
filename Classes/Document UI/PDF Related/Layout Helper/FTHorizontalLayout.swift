//
//  FTHorizontalLayout.swift
//  Noteshelf
//
//  Created by Amar on 02/03/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTHorizontalLayout: NSObject,FTLayouterInternal {
    private weak var scrollView : FTDocumentScrollView?;
    weak var document: FTDocumentProtocol?;
    weak var delegate: FTPageLayouterDelegate?;
    func findZoomFactor(_ pageCount: Int) -> CGFloat {
        return 1;
    }
    var layoutType : FTPageLayout {
        return .horizontal;
    }
    
    required init(withScrollView: FTDocumentScrollView) {
        super.init();
        self.scrollView = withScrollView;
    }
    
    func frame(for index: Int) -> CGRect {
        guard let _scrollView = self.scrollView else {
            return CGRect.zero;
        }
        let floatIndex = CGFloat(index);
        let pageWidth = _scrollView.frame.width;
        let offsetx = (pageWidth * floatIndex) + (floatIndex * UIScrollView.between_Page_offset);
        let offset = CGPoint.init(x: offsetx, y: 0);
        let pageFrame = CGRect.init(origin: offset, size: _scrollView.frame.size);
        return pageFrame;
    }
    
    func updateContentSize(pageCount : Int) {
        let lastPageFrame = self.frame(for: pageCount - 1);
        let contentSize = CGSize(width: lastPageFrame.maxX, height: lastPageFrame.height);
        self.scrollView?.updateContentHolderViewSize(contentSize);
    }
    
    func pages(in rect: CGRect) -> [Int] {
        var indices = [Int]();
        guard let _scrollView = self.scrollView else {
            return indices;
        }
        let pageWidth = _scrollView.frame.width + UIScrollView.between_Page_offset;
        let startX = rect.minX;
                
        let startPage = Int(floor((startX * 2 + pageWidth) / (pageWidth * 2)));
        indices.append(startPage);
        return indices;
    }
        
    func page(for point:CGPoint) -> Int {
        guard let _scrollView = self.scrollView else {
            return 0;
        }
        let pageWidth = _scrollView.frame.width + UIScrollView.between_Page_offset;
        let contentOffsetx = point.x;
        
        let pageIndex = floor((contentOffsetx * 2 + pageWidth) / (pageWidth * 2));
        return Int(pageIndex);
    }
}
