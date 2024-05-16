//
//  FTPresetEditView.swift
//  Noteshelf3
//
//  Created by Narayana on 07/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTFavoritePenColorEditView: View {
    @EnvironmentObject var viewModel: FTFavoritePresetsViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var editSegment: FTPenColorSegment = .grid
    @State var isScrollEnabled: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: FTSpacing.small) {
                    self.segmentControl
                    if editSegment == .grid {
                        FTFavoriteColorGridView()
                            .environmentObject(viewModel)
                            .onAppear {
                                self.isScrollEnabled = self.checkIfContentSizeIsBigger(geometry)
                            }
                    } else if editSegment == .spectrum {
                        FTFavoriteSpectrumView(color: self.viewModel.currentSelectedColor)
                            .environmentObject(viewModel)
                            .onAppear {
                                self.isScrollEnabled = self.checkIfContentSizeIsBigger(geometry)
                            }
                    }
                }
            }
            .onAppear {
                self.editSegment = FTPenColorSegment.savedSegment(for: .favorites, colorMode: .presetEdit)
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
        .frame(width: 308)
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
            Image(systemName: "trash")
                .foregroundColor(.red)
                .font(.appFont(for: .medium, with: 16.0))
                .onTapGesture {
                    self.viewModel.deleteColorAction()
                    self.viewModel.updateCurrentColors()
                    self.presentationMode.wrappedValue.dismiss()
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
            segment.saveSelection(for: .favorites, colorMode: .presetEdit)
        }
    }

    private func checkIfContentSizeIsBigger(_ geometry: GeometryProxy) -> Bool {
        let visibleSize = geometry.size
        let isBigger = visibleSize.height < self.editSegment.contentSize.height
        return isBigger
    }

    private var btnBack : some View {
        Button {
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

struct FTFavoriteSpectrumView: View {
    @State var color: String = blackColorHex
    @State private var colorSelectModeImage = FTPenColorSelectModeImage.add
    @State private var toUpdateUIView = false

    @StateObject private var hexInputVm = FTColorHexInputViewModel()
    @EnvironmentObject var viewModel: FTFavoritePresetsViewModel

    var body: some View {
        ZStack {
            VStack(spacing: FTSpacing.small) {
                FTSpectrumRepresentedView(color: $color, toUpdateUIview: $toUpdateUIView)
                    .frame(height: 256)
                FTFavHexFieldFooterView(colorSelectModeImage: $colorSelectModeImage)
                    .environmentObject(hexInputVm)
                    .environmentObject(viewModel)
            }
        }
        .onAppear {
            self.hexInputVm.text = viewModel.currentSelectedColor
        }
        .onChange(of: self.color) { color in
            if color != self.viewModel.currentSelectedColor {
                self.viewModel.updateCurrentSelection(colorHex: color)
                self.hexInputVm.text = color
            }
        }
        .onChange(of: self.viewModel.currentSelectedColor) { newValue in
            if newValue != self.color, let hex = newValue.getRequiredHex() {
                self.color = hex
                self.toUpdateUIView = true
            }
        }
    }
}

struct FTFavHexFieldFooterView: View {
    @State var hexChangeToBeObserved: Bool = false
    @Binding var colorSelectModeImage: FTPenColorSelectModeImage
    @EnvironmentObject var hexInputVm: FTColorHexInputViewModel
    @EnvironmentObject var viewModel: FTFavoritePresetsViewModel

    var body: some View {
        HStack(spacing: FTSpacing.zero) {
            Text("#")
                .padding(.leading)
                .padding(.trailing, FTSpacing.zero)
            TextField("",
                      text: $hexInputVm.text)
            .padding(.leading, FTSpacing.zero)
            .onChange(of: self.hexInputVm.text) { currentHex in
                if let reqHex = currentHex.getRequiredHex(), hexChangeToBeObserved {
                    self.viewModel.updateCurrentSelection(colorHex: reqHex)
                }
                hexChangeToBeObserved = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                if let reqHex = self.hexInputVm.text.getRequiredHex() {
                    self.hexInputVm.text = reqHex
                } else {
                    self.hexInputVm.text = self.viewModel.currentSelectedColor
                }
            }

            Spacer()

            VStack {
            }
            .frame(width: 97.0, height: 23.0)
            .background(Color(hex: self.viewModel.currentSelectedColor))
            .cornerRadius(6.0)
            .shadow(color: Color.appColor(.black4), radius: 1, x: 0.0, y: 3.0)
            .shadow(color: Color.appColor(.black3), radius: 1, x: 0.0, y: 3.0)
            .padding(.trailing, FTSpacing.small)

            Image(systemName: "eyedropper")
                .foregroundColor(Color.appColor(.accent))
                .font(Font.appFont(for: .regular, with: 16.0))
                .onTapGesture {
                    self.viewModel.didTapOnColorEyeDropper()
                }
            Spacer()
                .frame(width: 8.0)
        }
        .frame(height: 36.0)
        .background(Color.appColor(.gray60).opacity(0.12))
        .cornerRadius(10.0)
    }
}
