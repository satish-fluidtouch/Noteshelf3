//
//  View+Extensions.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 18/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI

extension View {
    func trashNavBarItems() -> some View {
#if !targetEnvironment(macCatalyst)
        modifier(FTTrashNavBarItemsViewModifier())
#else
        self
#endif
    }
    
    func shelfNavBarItems() -> some View {
#if !targetEnvironment(macCatalyst)
        modifier(FTShelfNavBarItemsViewModifier(appState: AppState(sizeClass: .regular)))
#else
        self
#endif
    }

    func shelfBottomToolbar() -> some View {
        modifier(FTShelfBottomToolBarViewModifier())
    }

    func popoverApperanceOperations(popoverIsShown: Binding<Bool>) -> some View {
        modifier(FTPopoverApperanceViewModifier(popoverIsShown:popoverIsShown))
    }

    func contextualMenuApperanceOperations() -> some View {
        modifier(ContextualMenuApperanceViewModifier())
    }
}
