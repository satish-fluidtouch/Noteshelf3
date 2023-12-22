//
//  FTPageLayouter.swift
//  Noteshelf
//
//  Created by Amar on 02/03/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let pageLayoutDidChange = Notification.Name(rawValue: "FTPageLayoutDidChange")
    static let pageLayoutWillChange = Notification.Name(rawValue: "FTPageLayoutWillChange")
}

@objc enum FTPageLayout: Int, CaseIterable {
    case vertical,horizontal;
    
    var localizedTitle: String {
        switch self {
        case .horizontal:
            return NSLocalizedString("PageScrollHorizontal", comment: "Horizontal");
        case .vertical:
            return NSLocalizedString("PageScrollVertical", comment: "Vertical");
        }
    }
}

protocol FTLayouterInternal: FTPageLayouter {
    init(withScrollView : FTDocumentScrollView);
}

@objc protocol FTPageLayouterDelegate: NSObjectProtocol {
    func yPosition() -> CGFloat;
}

@objc protocol FTPageLayouter: NSObjectProtocol {
    var layoutType : FTPageLayout { get };
    var document: FTDocumentProtocol? {get set};
    var delegate: FTPageLayouterDelegate? {get set};
    func frame(for index: Int) -> CGRect;
    func updateContentSize(pageCount : Int);
    func pages(in rect: CGRect) -> [Int];
    func page(for point:CGPoint) -> Int;
    var minZoomFactor: CGFloat {get};
}

class FTLayouterFactory: NSObject {
    static func layouter(type : FTPageLayout,scrollView : FTDocumentScrollView) -> FTPageLayouter {
        let layouter : FTPageLayouter;
        switch type {
        case .horizontal:
            layouter = FTHorizontalLayout(withScrollView: scrollView);
        case .vertical:
            layouter = FTVerticalLayout(withScrollView: scrollView);
        }
        return layouter;
    }
}

extension UserDefaults
{
    @objc dynamic var pageLayoutType: FTPageLayout {
        get {
            if let layoutType = FTPageLayout(rawValue: integer(forKey: "pageLayoutType")) {
                return layoutType
            }
            return .horizontal
        }
        set {
            if(newValue != self.pageLayoutType) {
                NotificationCenter.default.post(name: .pageLayoutWillChange, object: self);
                self.set(newValue.rawValue, forKey: "pageLayoutType")
                self.synchronize()
                NotificationCenter.default.post(name: .pageLayoutDidChange, object: self);
                FabricHelper.updatePageLayout(newValue);
            }
            if(newValue == .vertical) {
                self.verticalLayoutUsed = true;
            }
        }
    }
    
    @objc private(set) var verticalLayoutUsed: Bool {
        get {
            return self.bool(forKey: "verticalLayoutUsed");
        }
        set {
            self.set(newValue, forKey: "verticalLayoutUsed");
        }
    }
    
    var isVerticalLayoutPromoted: Bool {
        get {
            return self.bool(forKey: "verticalLayoutPromoted");
        }
        set {
            self.set(newValue, forKey: "verticalLayoutPromoted");
        }
    }
}

@objc extension UserDefaults {
    static func registerPageLayoutDefaults(freshInsstall : Bool) {
        if(freshInsstall) {
            UserDefaults.standard.set(FTPageLayout.vertical.rawValue, forKey: "pageLayoutType")
            UserDefaults.standard.synchronize();
        }
        else {
            if nil == UserDefaults.standard.object(forKey: "pageLayoutType") {
                UserDefaults.standard.set(FTPageLayout.horizontal.rawValue, forKey: "pageLayoutType")
                UserDefaults.standard.synchronize();
            }
        }
    }
}
