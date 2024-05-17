//
//  FTPresetEditView.swift
//  Noteshelf3
//
//  Created by Narayana on 07/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTPresetEditView: View {
    @EnvironmentObject var viewModel: FTPenShortcutViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var editSegment: FTPenColorSegment = .grid
    @State var isScrollEnabled: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: FTSpacing.small) {
                    self.segmentControl
                    if editSegment == .grid {
                        FTColorGridView(colorMode: .presetEdit)
                            .environmentObject(viewModel)
                            .onAppear {
                                self.isScrollEnabled = self.checkIfContentSizeIsBigger(geometry)
                            }
                    } else if editSegment == .spectrum {
                        FTSpectrumView(color: self.viewModel.currentSelectedColor, colorMode: .presetEdit)
                            .environmentObject(viewModel)
                            .onAppear {
                                self.isScrollEnabled = self.checkIfContentSizeIsBigger(geometry)
                            }
                    }
                }
            }
            .onAppear {
                self.editSegment = FTPenColorSegment.savedSegment(for: viewModel.colorsFlow, colorMode: .presetEdit)
            }
            .toolbar {
                self.toolBar
            }
            .scrollDisabled(!isScrollEnabled)
            // Observing height to update scrollEnabled during keyboard usage
            .onChange(of: geometry.size.height) { newHeight in
                self.isScrollEnabled = self.checkIfContentSizeIsBigger(geometry)
            }
        }
        .frame(width: 288)
        .navigationBarBackButtonHidden()
    }

    @ToolbarContentBuilder
    private var toolBar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            btnBack
        }

        ToolbarItem(placement: .principal) {
            Text("SelectColor".localized)
                .font(.clearFaceFont(for: .medium, with: 20.0))
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                self.viewModel.deleteColorAction()
                self.viewModel.updateCurrentColors()
                self.viewModel.updateColorEditViewSizeIfNeeded(isPresetEdit: false)
                self.presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.appFont(for: .medium, with: 16.0))
            }
        }
    }

    private var segmentControl: some View {
        Picker("", selection: $editSegment) {
            Text("shelf.notebook.textstyle.grid".localized)
                .tag(FTPenColorSegment.grid)
                .font(.appFont(for: .medium, with: 13.0))
            Text("Spectrum")
                .tag(FTPenColorSegment.spectrum)
                .font(.appFont(for: .medium, with: 13.0))
        }
        .pickerStyle(.segmented)
        .frame(height: 32.0)
        .onChange(of: editSegment) { segment in
            segment.saveSelection(for: viewModel.colorsFlow, colorMode: .presetEdit)
            self.viewModel.updateColorEditViewSizeIfNeeded(isPresetEdit: true)
        }
    }

    private func checkIfContentSizeIsBigger(_ geometry: GeometryProxy) -> Bool {
        let visibleSize = geometry.size
        let isBigger = visibleSize.height < self.editSegment.contentSize.height
        return isBigger
    }

    private var btnBack : some View {
        Button {
            self.viewModel.updateColorEditViewSizeIfNeeded(isPresetEdit: false)
            self.presentationMode.wrappedValue.dismiss()
        } label: {
            HStack {
                Image(systemName: "chevron.backward")
                    .foregroundColor(Color.appColor(.accent))
                    .font(.appFont(for: .regular, with: 16.0))
            }
        }
    }
}
