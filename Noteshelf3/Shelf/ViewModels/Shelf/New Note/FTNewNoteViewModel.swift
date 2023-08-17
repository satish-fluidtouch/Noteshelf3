//
//  FTNewNoteViewModel.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 18/05/22.
//

import Foundation
import FTStyles
import SwiftUI
struct FTNewNoteViewModel {
    func  getTintColorBasedOnMode(_ mode: FTShelfMode) -> Color {
        if mode == .normal {
            return Color.appColor(AssetsColor.black70)
        } else {
            return Color.appColor(AssetsColor.black20)
        }
    }
}
