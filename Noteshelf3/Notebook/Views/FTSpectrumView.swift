//
//  FTSpectrumView.swift
//  Noteshelf3
//
//  Created by Narayana on 06/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTSpectrumView: View {
    @State var color: String = blackColorHex
    @State private var colorSelectModeImage = FTPenColorSelectModeImage.add

    @StateObject private var hexInputVm = FTColorHexInputViewModel()
    @EnvironmentObject var viewModel: FTPenShortcutViewModel
    
    var colorMode: FTPenColorMode

    var body: some View {
        ZStack {
            VStack(spacing: FTSpacing.small) {
                FTSpectrumRepresentedView(color: $color)
                    .frame(width: 288, height: 244)
                FTHexFieldFooterView(colorSelectModeImage: $colorSelectModeImage, colorMode: colorMode)
                    .environmentObject(hexInputVm)
            }
        }            
        .padding(.bottom, FTSpacing.large)
        .onAppear {
            self.hexInputVm.text = self.color
        }
        .onChange(of: color) { color in
            if color != self.viewModel.currentSelectedColor {
                self.viewModel.updateCurrentSelection(colorHex: color)
                self.hexInputVm.text = color
            }
        }
    }
}
