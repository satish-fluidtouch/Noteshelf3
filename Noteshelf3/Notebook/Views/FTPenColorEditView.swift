//
//  FTPenColorShortcutEditView.swift
//  Noteshelf3
//
//  Created by Narayana on 15/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTPenColorEditView: View {
    @ObservedObject var viewModel: FTPenShortcutViewModel
    @State private var showRestoreAlert = false
    @State var isScrollEnabled: Bool = false

    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ScrollView {
                    VStack(spacing: FTSpacing.small) {
                        self.segmentControl
                        if self.viewModel.colorSelectSegment == .presets {
                            FTPresetColorsView(selectedPage: self.viewModel.requiredPresetPage())
                                .environmentObject(viewModel)
                                .onAppear {
                                    self.isScrollEnabled = self.checkIfContentSizeIsBigger(geometry)
                                }
                        } else if self.viewModel.colorSelectSegment == .grid {
                            FTColorGridView(colorMode: .select)
                                .environmentObject(viewModel)
                                .onAppear {
                                    self.isScrollEnabled = self.checkIfContentSizeIsBigger(geometry)
                                }
                        } else {
                            FTSpectrumView(color: self.viewModel.currentSelectedColor, colorMode: .select)
                                .environmentObject(self.viewModel)
                                .onAppear {
                                    self.isScrollEnabled = self.checkIfContentSizeIsBigger(geometry)
                                }
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .scrollDisabled(!isScrollEnabled)
                .toolbar {
                    self.toolBar
                }
            }
            // Observing height to update scrollEnabled during keyboard usage
            .onChange(of: geometry.size.height) { newHeight in
                self.isScrollEnabled = self.checkIfContentSizeIsBigger(geometry)
            }
        }
        .navigationViewStyle(.stack)
        .onDrop(of: [.text], delegate: FTColorDropOutDelegate(viewModel: self.viewModel))
    }

    private func checkIfContentSizeIsBigger(_ geometry: GeometryProxy) -> Bool {
        let visibleSize = geometry.size
        let isBigger = visibleSize.height < viewModel.colorSelectSegment.contentSize.height
        return isBigger
    }

    @ToolbarContentBuilder
    private var toolBar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Color".localized)
                .font(.clearFaceFont(for: .medium, with: 20.0))
        }
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                self.viewModel.didTapOnColorEyeDropper();
            } label: {
                Image(systemName: "eyedropper")
                    .foregroundColor(Color.appColor(.accent))
                    .font(Font.appFont(for: .regular, with: 16.0))
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                self.showRestoreAlert = true
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .foregroundColor(Color.appColor(.accent))
                    .font(Font.appFont(for: .regular, with: 16.0))
            }
            .alert(isPresented: $showRestoreAlert) {
                Alert(
                    title: Text("color.restorePresetColors.message".localized),
                    message: Text(""),
                    primaryButton: .destructive(Text("color.restoreAll".localized)) {
                        self.viewModel.restoreAction()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private var segmentControl: some View {
        Picker("", selection: $viewModel.colorSelectSegment) {
            Text("shelf.notebook.textstyle.Presets".localized)
                .tag(FTPenColorSegment.presets)
                .font(.appFont(for: .medium, with: 13.0))
            Text("shelf.notebook.textstyle.grid".localized)
                .tag(FTPenColorSegment.grid)
                .font(.appFont(for: .medium, with: 13.0))
            Text("colors.presets.spectrum".localized)
                .tag(FTPenColorSegment.spectrum)
                .font(.appFont(for: .medium, with: 13.0))
        }
        .pickerStyle(.segmented)
        .frame(width: 288.0, height: 32.0)
        .onChange(of: viewModel.colorSelectSegment) { segment in
            segment.saveSelection(for: viewModel.colorsFlow)
            viewModel.presetEditIndex = nil
            self.viewModel.updateColorEditViewSizeIfNeeded(isPresetEdit: false)
        }
    }
}
