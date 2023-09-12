//
//  FTNewNoteTopSectionView.swift
//  Noteshelf3
//
//  Created by Rakesh on 31/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon

struct FTNewNoteTopSectionView: View {
    @ObservedObject var viewModel: FTNewNotePopoverViewModel
    weak var delegate: FTShelfNewNoteDelegate?
    @EnvironmentObject var shelfViewModel: FTShelfViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Grid {
            GridRow {
                getShelfPopOverItemView(.quickNote)
                    .gridCellColumns(2)
            }
            GridRow{
                getShelfPopOverItemView(.newNotebook)
                getShelfPopOverItemView(.importFromFiles)
            }
        }
        .macOnlyPlainButtonStyle()
    }
    private func getShelfPopOverItemView(_ type: FTNewNotePopoverOptions) -> some View {
        FTNewNoteItemView(type: type, viewModel: viewModel)
            .buttonInteractionStyle(scaleValue: 0.99)
    }
}
struct FTNewNoteTopSectionView_Previews: PreviewProvider {
    static var previews: some View {
        FTNewNoteTopSectionView(viewModel: FTNewNotePopoverViewModel())
    }
}
