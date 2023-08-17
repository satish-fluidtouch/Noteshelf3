//
//  FTPopoverApperanceViewModifier.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 18/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI

struct FTPopoverApperanceViewModifier: ViewModifier {
    @EnvironmentObject var shelfViewModel: FTShelfViewModel
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo
    
    @Binding var popoverIsShown: Bool

    public func body(content: Content) -> some View {
        content.onAppear {
            popoverIsShown = true
            shelfMenuOverlayInfo.isMenuShown = true
        }
        .onDisappear {
            popoverIsShown = false
            shelfMenuOverlayInfo.isMenuShown = false
        }
    }
}

struct ContextualMenuApperanceViewModifier: ViewModifier {
    @EnvironmentObject var sidebarViewModel: FTSidebarViewModel
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo

    public func body(content: Content) -> some View {
        content.onAppear {
            shelfMenuOverlayInfo.isMenuShown = true
        }
        .onDisappear {
            shelfMenuOverlayInfo.isMenuShown = false
        }
    }
}
