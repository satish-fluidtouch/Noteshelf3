//
//  CustomNavBarPreferenceKeys.swift
//  Rooms
//
//  Created by srinivas on 12/07/22.
//

import Foundation
import SwiftUI

//@State private var showBackButton: Bool = true
//@State private var title: String = "Covers"

struct TitlePrefKey: PreferenceKey {
    
    static var defaultValue: String = "Covers"
    
    static func reduce(value: inout String, nextValue: () -> String) {
        value = nextValue()
    }
}

struct ShowBackButtonPrefKey: PreferenceKey {
    
    static var defaultValue: Bool = true
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

//struct closeButtonPrefKey: PreferenceKey {
//
//    static var defaultValue: Value
//}

extension View {
    
    func customNavTitle(_ title: String) -> some View {
       preference(key: TitlePrefKey.self, value: title)
    }
    
    func customNavBackButtonHidden(_ hidden: Bool) -> some View {
        preference(key: ShowBackButtonPrefKey.self, value: hidden)
    }
    
    func customNavbarItems(title: String = "", hidden: Bool = false) -> some View {
        self.customNavTitle(title)
            .customNavBackButtonHidden(hidden)
    }
}

//extension UINavigationController: UIGestureRecognizerDelegate {
//    override open func viewDidLoad() {
//        super.viewDidLoad()
//        interactivePopGestureRecognizer?.delegate = self
//    }
//
//    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        return viewControllers.count > 1
//    }
//}
