//
//  FTVerticalLayout.swift
//  Noteshelf
//
//  Created by Amar on 02/03/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTVerticalLayout: NSObject,FTLayouterInternal {
    private weak var scrollView : FTDocumentScrollView?;
    private var pageInfo = [String : CGRect]();
    weak var document: FTDocumentProtocol?;
    weak var delegate: FTPageLayouterDelegate?;

    static let firstPageOffsetY: CGFloat = 75.0

    var layoutType : FTPageLayout {
        return .vertical;
    }

    required init(withScrollView: FTDocumentScrollView) {
        super.init();
        self.scrollView = withScrollView;
    }
    
    func frame(for index: Int) -> CGRect {
        guard let _scrollView = self.scrollView,
            let contentHolderView = _scrollView.contentHolderView
            else {
            return CGRect.zero;
        }
        let scale = _scrollView.zoomFactor;
        var pageFrame = self.frame(forPageAt: index);
        pageFrame = CGRect.scale(pageFrame, scale);
        if(pageFrame.size.width < contentHolderView.frame.width) {
            pageFrame.origin.x = (contentHolderView.frame.width - pageFrame.size.width)*0.5;
        }
        pageFrame.size.height = pageFrame.height;
        pageFrame.size.width = pageFrame.width;
        return pageFrame;
    }
    
    func updateContentSize(pageCount : Int) {
        self.pageInfo.removeAll();
        var maxWidth: CGFloat = 0;
        for eachIndex in 0..<pageCount {
            let frame = self.frame(for: eachIndex);
            maxWidth = max(maxWidth,frame.width);
        }
        var lastPage = pageCount - 1;
        if(pageCount == 0) {
            FTCLSLog("Zero pages");
            lastPage = 0;
        }
        let lastPageFrame = self.frame(for: lastPage);
        let contentSize = CGSize(width: maxWidth, height: lastPageFrame.maxY);
        self.scrollView?.updateContentHolderViewSize(contentSize);
    }
    
    func page(for point:CGPoint) -> Int {
        guard let _scrollView = self.scrollView else {
            return 0;
        }
        let scale = _scrollView.zoomFactor;
        let startY = point.y/scale;
        let pageIndex = self.pageIndex(for: startY, edge: .top);
        return max(pageIndex,0);
    }

    func pages(in rect: CGRect) -> [Int] {
        var indices = [Int]();
        guard let _scrollView = self.scrollView else {
            return indices;
        }

        guard let pageCount = self.document?.pages().count,pageCount > 0 else {
            return indices;
        }
        let scale = _scrollView.zoomFactor;
        let startY = rect.minY;
        var startPage = self.startPageIndex(for: startY/scale);
        startPage = clamp(startPage, 0, pageCount - 1);
        
        let endY = min(rect.maxY,_scrollView.contentSize.height);
        var endPage = self.pageIndex(for: endY/scale,startFrom: startPage, edge: .bottom);
        if endPage != -1 {
            endPage = clamp(endPage, 0, pageCount - 1);
            for i in startPage...endPage {
                indices.append(i);
            }
        }
        else {
            indices.append(startPage);
        }
        return indices;
    }
}

func clamp<T>(_ value: T, _ minValue: T,_ maxValue: T) -> T where T : Comparable
{
    return min(max(value,minValue),maxValue);
}

private extension FTVerticalLayout
{
    func startPageIndex(for minY: CGFloat) -> Int {
        var indexToReturn: Int = -1;
        guard let pages = self.document?.pages() else {
            return indexToReturn;
        }
        
        let pageCount = pages.count;
        let pageJump = Int(sqrt(Double(pageCount)));
        
        let intMinY = ceil(minY);
        let point = CGPoint(x: 0, y: intMinY)

        var endPage: Int = 0,startPage: Int = 0,index: Int = 0;
        
        while(index < pageCount) {
            let pageFrame = self.frame(forPageAt: index).insetBy(dx: 0, dy: -UIScrollView.between_Page_offset);
            if(pageFrame.contains(point) || (pageFrame.minY > point.y)) {
                endPage = index;
                break;
            }
            else if(index + pageJump >= pageCount) {
                endPage = pageCount-1;
                break;
            }
            else {
                startPage = index;
                index += pageJump
            }
        }
        
        for index in startPage...endPage {
            let pageFrame = self.frame(forPageAt: index).insetBy(dx: 0, dy: -UIScrollView.between_Page_offset);
            if(pageFrame.contains(point)) {
                indexToReturn = index;
                break;
            }
        }

        return indexToReturn;
    }
    
    func pageIndex(for minY: CGFloat,startFrom : Int = 0,edge: UIRectEdge) -> Int {
        var indexToReturn: Int = -1;
        guard let pages = self.document?.pages() else {
            return indexToReturn;
        }
        let intMinY = ceil(minY);
        let point = CGPoint(x: 0, y: intMinY)

        var pageFound = false;
        let pageCount = pages.count;
        for index in startFrom..<pageCount {
            let pageFrame = self.frame(forPageAt: index).insetBy(dx: 0, dy: -UIScrollView.between_Page_offset);
            if(pageFrame.contains(point)) {
                indexToReturn = index;
                pageFound = true;
                if(edge == .top) {
                    break;
                }
            }
            else if pageFound,edge == .bottom {
                break;
            }
        }
        return indexToReturn;
    }

    func frame(forPageAt index: Int) -> CGRect {
        guard let _scrollView = self.scrollView,
              let pages = self.document?.pages(),
              pages.count > index else {
            return CGRect.zero;
        }

        let currentPage = pages[index];
        var rectToReturn = CGRect.zero;
        if let pageFrame = self.pageInfo[currentPage.uuid] {
            rectToReturn = pageFrame;
        }
        else {
            if(index == 0) {
                rectToReturn = CGRect.zero;
                if let yoffset = self.delegate?.yPosition() {
                    rectToReturn.origin.y += yoffset;
                }
            }
            else {
                let prevPageIndex = index-1;
                let prevPageFrame = self.frame(forPageAt: prevPageIndex);
                rectToReturn = prevPageFrame;
            }
            var pageRect = currentPage.pdfPageRect;
            let maxFrame = _scrollView.frame;
            pageRect.size = aspectFittedRect(pageRect, maxFrame).size;
            
            rectToReturn.origin.y = rectToReturn.maxY + ((index > 0) ? UIScrollView.between_Page_offset : 0);
            rectToReturn.size.height = pageRect.height;
            rectToReturn.size.width = pageRect.width;

            self.pageInfo[currentPage.uuid] = rectToReturn;
        }
        return rectToReturn;
    }
}
