//
//  FTSidebarViewNew.swift
//  NewShelfSidebar
//
//  Created by Ramakrishna on 13/04/23.
//

import SwiftUI

struct FTSidebarTopSectionView: View {
    @ObservedObject var viewModel: FTSidebarViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    weak var delegate: FTSidebarViewDelegate?
    var body: some View {
        VStack {
            FTSidebarTopSectionGridView(delegate: delegate, viewModel: viewModel)
        }
        .padding(.horizontal,20)
        .padding(.bottom,3)
    }
}
struct FTSidebarViewNew_Previews: PreviewProvider {
    static var previews: some View {
        FTSidebarTopSectionView(viewModel: FTSidebarViewModel(collection: nil))
    }
}
