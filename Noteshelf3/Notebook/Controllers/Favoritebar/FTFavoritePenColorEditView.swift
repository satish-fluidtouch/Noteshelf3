//
//  FTFavoritePenColorEditView.swift
//  Noteshelf3
//
//  Created by Narayana on 08/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTFavoritePenColorEditView: View {
    @State var editSegment: FTPenColorSegment = .grid
    @State var isScrollEnabled: Bool = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @EnvironmentObject var viewModel: FTFavoritePresetsViewModel

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: FTSpacing.extraSmall) {
                }
            }
        }
    }
}
