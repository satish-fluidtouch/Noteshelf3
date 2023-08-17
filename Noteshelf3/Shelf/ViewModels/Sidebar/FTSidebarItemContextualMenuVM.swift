//
//  FTSidebarItemContextualMenuViewModel.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 20/04/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI

class FTSidebarItemContextualMenuVM: ObservableObject {
    @Published var performAction: FTSidebarItemContextualOption?
    @Published var sideBarItem: FTSideBarItem?
}
