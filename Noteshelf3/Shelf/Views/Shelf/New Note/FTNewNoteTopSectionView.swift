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
//    weak var viewDelegate: FTShelfNewNotePopoverViewDelegate?
    @Environment(\.dismiss) var dismiss
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        Grid {
            if isLargeSize() {
                GridRow {
                    getShelfPopOverItemView(.quickNote)
                }
                GridRow{
                    getShelfPopOverItemView(.newNotebook)
                }
                GridRow{
                    getShelfPopOverItemView(.importFromFiles)
                }

            } else {
                GridRow {
                    getShelfPopOverItemView(.quickNote)
                        .gridCellColumns(2)
                }
                GridRow{
                    getShelfPopOverItemView(.newNotebook)
                    getShelfPopOverItemView(.importFromFiles)
                }
            }
        }
    }
    private func getShelfPopOverItemView(_ type: FTNewNotePopoverOptions) -> some View {
        FTNewNoteItemView(type: type, viewModel: viewModel)
    }
    
    func isLargeSize() -> Bool {
        return isLargerTextEnabled(for: dynamicTypeSize)
    }
}
struct FTNewNoteTopSectionView_Previews: PreviewProvider {
    static var previews: some View {
        FTNewNoteTopSectionView(viewModel: FTNewNotePopoverViewModel())
    }
}
