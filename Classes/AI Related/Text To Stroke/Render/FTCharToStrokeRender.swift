//
//  FTCharToStrokeRender.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 27/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

struct FTTextToStrokeProperties {
    static let leftMargin: CGFloat = 48;
    static let rightMargin: CGFloat = 48;
    static let spaceCharWidth: CGFloat = 20;
    static let verticalLineSpacing: CGFloat = 0;
    static let paragraphMargin: CGFloat = 20;
    static let topMargin: CGFloat = 64;
    static let bottomMargin: CGFloat = 40;

    static let defaultOrigin: CGPoint = CGPoint(x: leftMargin, y: topMargin);
}

enum FTTextWrapType: Int {
    case word,char;
}

typealias FTStrokeRenderOnUpdateCallback = (_ annotations: [FTAnnotation], _ page: FTPageProtocol?, _ createNewPage: Bool) -> (FTPageProtocol?);
typealias FTStrokeRenderOnCompleteCallback = () -> ();

class FTCharToStrokeRender: NSObject {
    internal var strokesToAdd = [FTAnnotation]();
    
    private(set) var pageRect: CGRect = .zero;
    private(set) var pageScale: CGFloat = 1;
    private var strokeRenderScale: CGFloat = 1;
    var lineHeight: CGFloat {
        return (FTTextToStrokeDataProvider.sharedInstance.glyphHeight * pageScale) + FTTextToStrokeProperties.verticalLineSpacing;
    }

    private(set) var strokeColor: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1);
    
    static func renderer(_ type: FTTextWrapType = .word) -> FTCharToStrokeRender {
        let renderer: FTCharToStrokeRender;
        switch (type) {
        case .word:
            renderer = FTWordWrapStrokeRender();
        case .char:
            renderer = FTCharWrapStrokeRender();
        }
        return renderer;
    }
        
    func convertTextToStroke(for page: FTPageProtocol
                             ,content: String
                             , origin inOrigin: CGPoint
                             , onUpdate: @escaping  FTStrokeRenderOnUpdateCallback
                             , onComplete: @escaping FTStrokeRenderOnCompleteCallback) {
        fatalError("\(Self.className) should overide \(#function)")
    }
    
    func convertTextToStroke(for page: FTPageProtocol, string: String,origin inOrigin: CGPoint) -> [FTAnnotation] {
        fatalError("\(Self.className) should overide \(#function)")
    }
    
    internal func updatePageProperties(_ inPage:FTPageProtocol) {
        self.pageRect = inPage.pdfPageRect
        let pageLineHieght = inPage.lineHeight;
#if DEBUG
        if FTDeveloperOption.textToStrokeSnapToLineHeight {
            self.pageScale = pageLineHieght.toCGFloat() / FTTextToStrokeDataProvider.sharedInstance.glyphHeight;
        }
        else {
            let widthScale: CGFloat = inPage.pdfPageRect.width / FTTextToStrokeDataProvider.sharedInstance.referenePageSize.width;
            let heightScale: CGFloat = inPage.pdfPageRect.height / FTTextToStrokeDataProvider.sharedInstance.referenePageSize.height;
            
            var _pageScale = min(widthScale, heightScale);
            _pageScale /= 2;
            self.pageScale = _pageScale;
        }
#else
        self.pageScale = pageLineHieght.toCGFloat() / FTTextToStrokeDataProvider.sharedInstance.glyphHeight;
#endif
//        var lineHeight = inPage.lineHeight.toCGFloat();
//        let height = lineHeight < 40 ? lineHeight * 1.5 : lineHeight;
        self.strokeRenderScale = self.pageScale;//height / FTTextToStrokeDataProvider.sharedInstance.glyphHeight;
        
        if inPage.templateInfo.isTemplate, let bgColor = (inPage as? FTPageBackgroundColorProtocol)?.pageBackgroundColor {
            self.strokeColor = bgColor.blackOrWhiteContrastingColor() ?? UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        }
    }
    
    func drawStroke(strokesInfo: FTCharStrokeInfo
                    ,origin: inout CGPoint) -> (strokes: [FTAnnotation],rect: CGRect) {
        var strokesToAdd = [FTAnnotation]();
        
        let strokes = strokesInfo.strokes;
        strokesToAdd.append(contentsOf: strokes);
        
        let strokeScale = strokeRenderScale;
        let strokeFontInfo = strokesInfo.glyphInfo.scaledInfo(strokeScale);

        let initialStrokeUnionRect = strokesInfo.strokeBoundingRect;
        let scaledUnionRect = CGRectScale(initialStrokeUnionRect, strokeScale);
        
        var dx = origin.x - initialStrokeUnionRect.origin.x;
        
        let offsetwidth: CGFloat = (scaledUnionRect.width - strokeFontInfo.fontWidth);
        let strokeOffsetX: CGFloat = strokeFontInfo.lsb;
        let originXToConsider = origin.x + strokeOffsetX - offsetwidth;
        dx = originXToConsider - initialStrokeUnionRect.origin.x;

        let strokeOffsetY = strokeFontInfo.y;
        let originToConsider = origin.y + (scaledUnionRect.origin.y - strokeOffsetY);
        let dy = originToConsider - initialStrokeUnionRect.origin.y;
        
        var rectOnAdd: CGRect = .null;
        strokes.forEach { eachStroke in
            let boundingRect = eachStroke.boundingRect;
            
            let xOffsetfromref:CGFloat = (boundingRect.minX - initialStrokeUnionRect.minX)*(strokeScale-1);
            let yOffsetfromref:CGFloat = (boundingRect.minY - initialStrokeUnionRect.minY)*(strokeScale-1);
            eachStroke.apply(strokeScale)

            let offset = CGPoint(x:dx+xOffsetfromref, y:dy+yOffsetfromref);
            eachStroke.setOffset(offset)

            rectOnAdd = rectOnAdd.union(eachStroke.boundingRect);
            eachStroke.strokeColor = self.strokeColor;
        }
        origin.x += (strokeFontInfo.width + offsetwidth);
        return (strokesToAdd,rectOnAdd);
    }
}

internal extension FTCharToStrokeRender {
    func createNewPageIfNeeded(origin: inout CGPoint
                               , isLastChar: Bool
                               ,currentPage: FTPageProtocol
                               ,createPageCallBack: FTStrokeRenderOnUpdateCallback) -> FTPageProtocol? {
        var pageToReturn: FTPageProtocol?
        if currentPage.isAtTheEndOfPage(origin)
            , let newPage = createPageCallBack(self.strokesToAdd,currentPage,!isLastChar) {
            pageToReturn = newPage;
            self.updatePageProperties(newPage);
            let startOrigin = newPage.startMargin;
            origin.x = startOrigin.x;
            origin.y = startOrigin.y;
            strokesToAdd.removeAll();
        }
        return pageToReturn;
    }
    
    func gotoNextParagraph(_ page:FTPageProtocol,origin : inout CGPoint) {
        origin.x = page.startMargin.x + FTTextToStrokeProperties.paragraphMargin;
        origin.y += self.lineHeight;
    }
    
    func gotoNextLine(_ page:FTPageProtocol,origin : inout CGPoint) {
        if page.startMargin.x > 0 {
            origin.x = page.startMargin.x;
        }
        else {
            origin.x = FTTextToStrokeProperties.leftMargin;
        }
        origin.y += self.lineHeight;
    }

}
