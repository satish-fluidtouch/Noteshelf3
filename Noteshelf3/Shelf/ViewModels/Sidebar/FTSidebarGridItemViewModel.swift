//
//  FTSidebarGridItemViewModel.swift
//  NewShelfSidebar
//
//  Created by Ramakrishna on 13/04/23.
//
import SwiftUI

import Foundation
class FTSidebarGridItemViewModel:ObservableObject {
    var backgroundColor: Color {
        if isActive {
            return Color.red
        }
        return Color.green
    }
    var isActive: Bool = false
}
