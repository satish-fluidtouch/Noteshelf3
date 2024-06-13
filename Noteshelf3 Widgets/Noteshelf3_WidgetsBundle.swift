//
//  Noteshelf3_WidgetsBundle.swift
//  Noteshelf3 Widgets
//
//  Created by Ramakrishna on 05/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
struct Noteshelf3_WidgetsBundle: WidgetBundle {
    var body: some Widget {
        NotebookCreation_Widget()
        FTPinnedWidget()
        FTQuickNoteCreateWidget()
        FTPinnedNotebookOptionsWidget()
    }
}

enum FTWidgetType {
    case small
    case medium

    // Reference sizes from figma to make dynamic spacings, alignments
    var size: CGSize {
        let size: CGSize
        switch self {
        case .small:
            size = CGSize(width: 155, height: 155)
        case .medium:
            size = CGSize(width: 342, height: 155)
        }
        return size
    }
}
