//
//  FTNewNoteTopSectionView.swift
//  Noteshelf3
//
//  Created by Rakesh on 31/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTNewNoteTopSectionView: View {
    @ObservedObject var viewModel: FTNewNotePopoverViewModel
    weak var delegate: FTShelfNewNoteDelegate?
//    weak var viewDelegate: FTShelfNewNotePopoverViewDelegate?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Grid {
            GridRow {
                getShelfPopOverItemView(.quickNote)
                    .gridCellColumns(2)
                    .onTapGesture {
                        self.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            viewModel.delegate?.quickCreateNewNotebook()
                        }
                    }
            }
            GridRow{
                getShelfPopOverItemView(.newNotebook)
                    .onTapGesture {
                        self.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01){
                            viewModel.delegate?.showNewNotebookPopover()
                        }
                    }
                getShelfPopOverItemView(.importFromFiles)
                    .onTapGesture {
                        self.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01){
                        delegate?.didClickImportNotebook()
                    }
                }
            }
        }
    }
    private func getShelfPopOverItemView(_ type: FTNewNotePopoverOptions) -> some View {
        FTNewNoteItemView(type: type)
    }
}
struct FTNewNoteTopSectionView_Previews: PreviewProvider {
    static var previews: some View {
        FTNewNoteTopSectionView(viewModel: FTNewNotePopoverViewModel())
    }
}
