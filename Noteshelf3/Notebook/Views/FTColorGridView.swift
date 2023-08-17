//
//  FTColorGridView.swift
//  Noteshelf3
//
//  Created by Narayana on 20/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles
import Combine

struct FTColorGridView: View {
    @StateObject var gridVm = FTColorGridModel()
    @StateObject var hexInputVm = FTColorHexInputViewModel()

    @State private var colorSelectModeImage = FTPenColorSelectModeImage.add
    // To avoid hex input initalization get observed
    @State var hexChangeToBeObserved = false
    @State var touchLocation: CGPoint?

    @EnvironmentObject var viewModel: FTPenShortcutViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var colorMode: FTPenColorMode
    var showDeleteButton: Bool = false

    var body: some View {
        ZStack {
            VStack(spacing: FTSpacing.small) {
                self.colorsGridView
                self.hexFieldView
            }
            .padding(.bottom, FTSpacing.large)
        }
        .coordinateSpace(name: "screen")
        .navigationBarBackButtonHidden()
        
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                btnBack
            }

            ToolbarItem(placement: .principal) {
                Text(colorMode == .presetEdit ? "SelectColor".localized : "Color".localized)
                    .font(.clearFaceFont(for: .medium, with: 20.0))
            }

            if showDeleteButton {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.appFont(for: .medium, with: 16.0))
                        .onTapGesture {
                            self.viewModel.deleteColorAction()
                            self.viewModel.updateCurrentColors()
                            self.viewModel.updateColorEditViewSizeIfNeeded(isPresetEdit: false)
                            self.presentationMode.wrappedValue.dismiss()
                        }
                }
            }
        }
        .onAppear {
            self.hexInputVm.text = self.viewModel.currentSelectedColor
        }
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
        .isHidden(self.colorMode == .select)
    }

    private var colorsGridView: some View {
        LazyVGrid(columns: gridItemLayout, spacing: FTSpacing.zero) {
            ForEach(0..<self.gridVm.gridColors.count, id: \.self) { index in
                let gridColor = self.gridVm.gridColors[index]
                let color = gridColor.color
                HStack {
                }.frame(width: 24.0,height: 24.0)
                    .zIndex(self.isSelectedColor(colorModel: gridColor) ? 1 : 0)
                    .background(
                        GeometryReader { geometry in
                            Color(hex: color)
                                .onFirstAppear(perform: {
                                    gridColor.location = geometry.frame(in: CoordinateSpace.named("screen"))
                                })
                        })
                    .overlay(self.isSelectedColor(colorModel: gridColor) ? Image("selectedGrid").resizable().frame(width: 27.0, height: 27.0).shadow(color: Color.appColor(.black20), radius: 2.0, x: 0.0, y: 0.0) : nil)
                        .onTapGesture {
                        colorSelectModeImage = .add
                        self.hexInputVm.text = color
                        self.viewModel.updateCurrentSelection(colorHex: color)
                    }

                    .gesture(DragGesture(coordinateSpace: .named("screen"))
                        .onChanged { value in
                            self.touchLocation = value.location
                        })
            }
            .onChange(of: self.touchLocation) { newValue in
                if let loc = self.touchLocation, let gridColor =  self.gridVm.getGridColor(at: loc) {
                    self.hexInputVm.text = gridColor.color
                }
            }
        }
        .frame(width: 288.0, height: 244.0)
        .padding(.horizontal, FTSpacing.large)
    }

    private func isSelectedColor(colorModel: FTGridColor) -> Bool {
        return self.viewModel.currentSelectedColor == colorModel.color
    }

    private var hexFieldView: some View {
        HStack(spacing: FTSpacing.zero) {
            Text("#")
                .padding(.leading)
                .padding(.trailing, FTSpacing.zero)
            TextField("",
                      text: $hexInputVm.text)
            .padding(.leading, FTSpacing.zero)
            .onChange(of: self.hexInputVm.text) { currentHex in
                if let reqHex = self.getRequiredHex(currentHex: currentHex), hexChangeToBeObserved {
                    self.viewModel.updateCurrentSelection(colorHex: reqHex)
                }
                hexChangeToBeObserved = true
            }
            .onSubmit {
                if let reqHex = self.getRequiredHex(currentHex: self.hexInputVm.text) {
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
            
            if colorMode == .select {
                Image(systemName: colorSelectModeImage.rawValue)
                    .foregroundColor(Color.appColor(.accent))
                    .onTapGesture {
                        if colorSelectModeImage == .add {
                            self.viewModel.addSelectedColorToPresets()
                            self.viewModel.updateCurrentColors()
                            colorSelectModeImage = .done
                        }
                    }
            } else {
                Image(systemName: "eyedropper")
                    .foregroundColor(Color.appColor(.accent))
                    .font(Font.appFont(for: .regular, with: 16.0))
                    .onTapGesture {
                        self.viewModel.didTapOnColorEyeDropper()
                    }
            }
            Spacer()
                .frame(width: 8.0)
        }
        .frame(width: 288.0, height: 36.0)
        .background(Color.appColor(.gray60).opacity(0.12))
        .cornerRadius(10.0)
        .padding(.horizontal)
    }

    private var gridItemLayout: [GridItem] {
        return [GridItem(.adaptive(minimum: 24.0, maximum: 24.0), spacing: FTSpacing.zero)]
    }

    private func getRequiredHex(currentHex: String) -> String? {
        if currentHex.count == 6 {
            return currentHex
        } else {
            var reqHex: String = currentHex
            if (currentHex.count > 3) {
                reqHex = (reqHex as NSString).substring(from: 1)
                let uiColor = UIColor(hexString: reqHex)
                reqHex = uiColor.hexString
                return reqHex
            }
            return nil
        }
    }

    private enum FTPenColorSelectModeImage: String {
        case add = "plus.circle.fill"
        case done = "checkmark.circle.fill"
    }
}

struct FTColorGridView_Previews: PreviewProvider {
    static var previews: some View {
        FTColorGridView(colorMode: .presetEdit)
            .environmentObject(FTPenShortcutViewModel(rackData: FTRackData(type: .pen, userActivity: nil)))
    }
}
